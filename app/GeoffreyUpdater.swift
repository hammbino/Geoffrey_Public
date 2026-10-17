import CryptoKit
import Foundation

struct GeoffreyUpdateArchive: Codable, Equatable {
    let url: String
    let sha256: String
    let bytes: Int64
}

struct GeoffreyUpdatePayload: Codable, Equatable {
    let schemaVersion: Int
    let version: String
    let build: Int
    let publishedAt: String
    let minimumMacOS: String
    let releaseNotes: String
    let archive: GeoffreyUpdateArchive

    enum CodingKeys: String, CodingKey {
        case version, build, archive
        case schemaVersion = "schema_version"
        case publishedAt = "published_at"
        case minimumMacOS = "minimum_macos"
        case releaseNotes = "release_notes"
    }
}

struct GeoffreySignedUpdateEnvelope: Codable {
    let payload: String
    let signature: String
}

enum GeoffreyUpdateVerificationError: LocalizedError {
    case malformedEnvelope
    case invalidSignature
    case invalidManifest

    var errorDescription: String? {
        switch self {
        case .malformedEnvelope:
            return "The update information was not in Geoffrey’s signed format."
        case .invalidSignature:
            return "The update information was not signed by Geoffrey’s publisher."
        case .invalidManifest:
            return "The signed update information contains an unsafe or unsupported value."
        }
    }
}

enum GeoffreyUpdateVerifier {
    static let maximumArchiveBytes: Int64 = 500 * 1024 * 1024
    static let maximumReleaseNotesCharacters = 20_000

    static func verifyEnvelope(_ data: Data, publicKeyBase64: String) throws -> GeoffreyUpdatePayload {
        guard data.count <= 1_000_000,
              let envelope = try? JSONDecoder().decode(GeoffreySignedUpdateEnvelope.self, from: data),
              let payloadData = Data(base64Encoded: envelope.payload),
              let signature = Data(base64Encoded: envelope.signature),
              let publicKeyData = Data(base64Encoded: publicKeyBase64),
              publicKeyData.count == 32,
              signature.count == 64 else {
            throw GeoffreyUpdateVerificationError.malformedEnvelope
        }

        let publicKey: Curve25519.Signing.PublicKey
        do {
            publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
        } catch {
            throw GeoffreyUpdateVerificationError.malformedEnvelope
        }
        guard publicKey.isValidSignature(signature, for: payloadData) else {
            throw GeoffreyUpdateVerificationError.invalidSignature
        }
        guard let payload = try? JSONDecoder().decode(GeoffreyUpdatePayload.self, from: payloadData),
              payload.schemaVersion == 1,
              validVersion(payload.version),
              payload.build > 0,
              validVersion(payload.minimumMacOS),
              payload.releaseNotes.count <= maximumReleaseNotesCharacters,
              payload.archive.bytes > 0,
              payload.archive.bytes <= maximumArchiveBytes,
              validSHA256(payload.archive.sha256),
              let archiveURL = URL(string: payload.archive.url),
              archiveURL.scheme?.lowercased() == "https",
              archiveURL.user == nil,
              archiveURL.password == nil else {
            throw GeoffreyUpdateVerificationError.invalidManifest
        }
        return payload
    }

    static func isNewer(
        candidateVersion: String,
        candidateBuild: Int,
        currentVersion: String,
        currentBuild: Int
    ) -> Bool {
        let candidateParts = numericVersion(candidateVersion)
        let currentParts = numericVersion(currentVersion)
        let count = max(candidateParts.count, currentParts.count)
        for index in 0..<count {
            let candidate = index < candidateParts.count ? candidateParts[index] : 0
            let current = index < currentParts.count ? currentParts[index] : 0
            if candidate != current { return candidate > current }
        }
        return candidateBuild > currentBuild
    }

    static func versionAtLeast(_ version: String, minimum: String) -> Bool {
        if version == minimum { return true }
        return isNewer(candidateVersion: version, candidateBuild: 0, currentVersion: minimum, currentBuild: 0)
    }

    static func sha256(of url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var digest = SHA256()
        while true {
            let data = try handle.read(upToCount: 1_048_576) ?? Data()
            if data.isEmpty { break }
            digest.update(data: data)
        }
        return digest.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func archiveEntriesAreSafe(_ entries: [String]) -> Bool {
        guard !entries.isEmpty, entries.count <= 20_000 else { return false }
        return entries.allSatisfy { entry in
            let components = entry.split(separator: "/", omittingEmptySubsequences: false)
            guard !entry.hasPrefix("/"), !entry.contains("\\"),
                  components.first == "Geoffrey.app",
                  components.count > 1 else { return false }
            return components.enumerated().allSatisfy { index, component in
                if component.isEmpty { return index == components.count - 1 }
                return component != "." && component != ".."
            }
        }
    }

    private static func numericVersion(_ value: String) -> [Int] {
        value.split(separator: ".").map { Int($0) ?? 0 }
    }

    private static func validVersion(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        return (2...4).contains(parts.count) && parts.allSatisfy { part in
            !part.isEmpty && part.allSatisfy(\.isNumber) && Int(part) != nil
        }
    }

    private static func validSHA256(_ value: String) -> Bool {
        value.count == 64 && value.allSatisfy { character in
            character.isNumber || ("a"..."f").contains(character)
        }
    }
}

#if !UPDATER_LOGIC_ONLY
import AppKit
import Security

enum GeoffreyUpdateCheckResult {
    case unavailable(String)
    case current(String)
    case available(GeoffreyUpdatePayload)
}

enum GeoffreyUpdaterError: LocalizedError {
    case configuration(String)
    case network(String)
    case package(String)
    case signing(String)
    case installation(String)

    var errorDescription: String? {
        switch self {
        case let .configuration(message), let .network(message), let .package(message),
             let .signing(message), let .installation(message):
            return message
        }
    }
}

enum GeoffreyUpdater {
    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static var currentBuild: Int {
        Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0") ?? 0
    }

    static var previousAppURL: URL? {
        updatesRoot?.appendingPathComponent("Previous/Geoffrey.app", isDirectory: true)
    }

    static var previousVersion: String? {
        guard let url = previousAppURL,
              let bundle = Bundle(url: url),
              let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return nil }
        return version
    }

    static func check() async -> GeoffreyUpdateCheckResult {
        guard let rawURL = Bundle.main.object(forInfoDictionaryKey: "GeoffreyUpdateManifestURL") as? String,
              let url = URL(string: rawURL), url.scheme?.lowercased() == "https" else {
            return .unavailable("Signed updates are not configured in this build.")
        }
        guard let publicKey = Bundle.main.object(forInfoDictionaryKey: "GeoffreyUpdatePublicKey") as? String,
              !publicKey.isEmpty else {
            return .unavailable("Signed updates will become available with Geoffrey’s release build.")
        }
        do {
            _ = try publisherTeamIdentifier(at: Bundle.main.bundleURL)
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  http.url?.scheme?.lowercased() == "https" else {
                throw GeoffreyUpdaterError.network("Geoffrey could not reach the signed update feed.")
            }
            let payload = try GeoffreyUpdateVerifier.verifyEnvelope(data, publicKeyBase64: publicKey)
            let system = ProcessInfo.processInfo.operatingSystemVersion
            let systemVersion = "\(system.majorVersion).\(system.minorVersion).\(system.patchVersion)"
            guard GeoffreyUpdateVerifier.versionAtLeast(systemVersion, minimum: payload.minimumMacOS) else {
                return .unavailable("Geoffrey \(payload.version) requires macOS \(payload.minimumMacOS) or later.")
            }
            guard GeoffreyUpdateVerifier.isNewer(
                candidateVersion: payload.version,
                candidateBuild: payload.build,
                currentVersion: currentVersion,
                currentBuild: currentBuild
            ) else {
                return .current("Geoffrey \(currentVersion) is up to date.")
            }
            return .available(payload)
        } catch let error as LocalizedError {
            return .unavailable(error.errorDescription ?? "Geoffrey could not verify the update.")
        } catch {
            return .unavailable("Geoffrey could not verify the update. Nothing was downloaded or changed.")
        }
    }

    static func stage(_ payload: GeoffreyUpdatePayload) async throws -> URL {
        guard let archiveURL = URL(string: payload.archive.url) else {
            throw GeoffreyUpdaterError.package("The signed update has an invalid download address.")
        }
        guard let root = updatesRoot else {
            throw GeoffreyUpdaterError.installation("Geoffrey could not open its private update folder.")
        }
        let manager = FileManager.default
        try manager.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let staging = root.appendingPathComponent("Staging-\(UUID().uuidString)", isDirectory: true)
        try manager.createDirectory(at: staging, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        do {
            let (temporaryURL, response) = try await URLSession.shared.download(from: archiveURL)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  http.url?.scheme?.lowercased() == "https" else {
                throw GeoffreyUpdaterError.network("The signed Geoffrey update could not be downloaded.")
            }
            let archive = staging.appendingPathComponent("Geoffrey.zip")
            try manager.moveItem(at: temporaryURL, to: archive)
            let attributes = try manager.attributesOfItem(atPath: archive.path)
            let bytes = (attributes[.size] as? NSNumber)?.int64Value ?? -1
            guard bytes == payload.archive.bytes else {
                throw GeoffreyUpdaterError.package("The downloaded update was incomplete, so Geoffrey left the current app unchanged.")
            }
            let digest = try GeoffreyUpdateVerifier.sha256(of: archive)
            guard digest == payload.archive.sha256 else {
                throw GeoffreyUpdaterError.package("The downloaded update did not match its signed checksum, so Geoffrey refused it.")
            }
            try validateArchive(at: archive)
            let expanded = staging.appendingPathComponent("Expanded", isDirectory: true)
            try manager.createDirectory(at: expanded, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            let extraction = run("/usr/bin/ditto", ["-x", "-k", archive.path, expanded.path])
            guard extraction.status == 0 else {
                throw GeoffreyUpdaterError.package("Geoffrey could not safely open the verified update package.")
            }
            let candidate = expanded.appendingPathComponent("Geoffrey.app", isDirectory: true)
            try rejectSymbolicLinks(in: candidate)
            try verifyCandidate(at: candidate, payload: payload)
            return candidate
        } catch {
            try? manager.removeItem(at: staging)
            throw error
        }
    }

    static func beginInstall(candidate: URL, payload: GeoffreyUpdatePayload) throws {
        guard let helper = Bundle.main.url(forResource: "GeoffreyUpdateHelper", withExtension: nil),
              let backup = previousAppURL else {
            throw GeoffreyUpdaterError.installation("The signed update helper is missing from this Geoffrey build.")
        }
        let current = Bundle.main.bundleURL
        guard FileManager.default.isWritableFile(atPath: current.deletingLastPathComponent().path) else {
            throw GeoffreyUpdaterError.installation("Geoffrey cannot replace the app in this folder. Move Geoffrey to your Applications folder and try again.")
        }
        let team = try publisherTeamIdentifier(at: current)
        let process = Process()
        process.executableURL = helper
        process.arguments = [
            "install",
            "--current", current.path,
            "--candidate", candidate.path,
            "--backup", backup.path,
            "--pid", String(ProcessInfo.processInfo.processIdentifier),
            "--bundle-id", "com.geoffrey.assistant",
            "--team-id", team,
            "--version", payload.version,
            "--build", String(payload.build),
        ]
        try process.run()
    }

    static func beginRollback() throws {
        guard let helper = Bundle.main.url(forResource: "GeoffreyUpdateHelper", withExtension: nil),
              let previous = previousAppURL,
              FileManager.default.fileExists(atPath: previous.path),
              let root = updatesRoot else {
            throw GeoffreyUpdaterError.installation("No previous Geoffrey version is available to restore.")
        }
        let current = Bundle.main.bundleURL
        let team = try publisherTeamIdentifier(at: current)
        let displaced = root.appendingPathComponent("Replaced/Geoffrey-\(currentVersion)-\(currentBuild).app", isDirectory: true)
        let process = Process()
        process.executableURL = helper
        process.arguments = [
            "rollback",
            "--current", current.path,
            "--candidate", previous.path,
            "--backup", displaced.path,
            "--pid", String(ProcessInfo.processInfo.processIdentifier),
            "--bundle-id", "com.geoffrey.assistant",
            "--team-id", team,
        ]
        try process.run()
    }

    private static var updatesRoot: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Geoffrey/Updates", isDirectory: true)
    }

    private static func validateArchive(at archive: URL) throws {
        let listing = run("/usr/bin/zipinfo", ["-1", archive.path])
        guard listing.status == 0 else {
            throw GeoffreyUpdaterError.package("Geoffrey could not inspect the verified update archive.")
        }
        let entries = listing.output.split(separator: "\n").map(String.init)
        guard GeoffreyUpdateVerifier.archiveEntriesAreSafe(entries) else {
            throw GeoffreyUpdaterError.package("The update archive contains an unsafe path and was refused.")
        }
    }

    private static func verifyCandidate(at candidate: URL, payload: GeoffreyUpdatePayload) throws {
        guard let bundle = Bundle(url: candidate),
              bundle.bundleIdentifier == "com.geoffrey.assistant",
              bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String == payload.version,
              Int(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") == payload.build else {
            throw GeoffreyUpdaterError.package("The verified package does not contain the promised Geoffrey version.")
        }
        let team = try publisherTeamIdentifier(at: Bundle.main.bundleURL)
        try verifyPublisher(at: candidate, teamIdentifier: team)
    }

    private static func rejectSymbolicLinks(in root: URL) throws {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isSymbolicLinkKey],
            options: [],
            errorHandler: { _, _ in false }
        ) else {
            throw GeoffreyUpdaterError.package("Geoffrey could not inspect the extracted update.")
        }
        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
            if values.isSymbolicLink == true {
                throw GeoffreyUpdaterError.package("The update contains an unsupported symbolic link and was refused.")
            }
        }
    }

    private static func publisherTeamIdentifier(at url: URL) throws -> String {
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode) == errSecSuccess,
              let staticCode else {
            throw GeoffreyUpdaterError.signing("Geoffrey could not inspect the app’s publisher signature.")
        }
        var signingInformation: CFDictionary?
        guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &signingInformation) == errSecSuccess,
              let information = signingInformation as? [String: Any],
              let team = information[kSecCodeInfoTeamIdentifier as String] as? String,
              !team.isEmpty else {
            throw GeoffreyUpdaterError.signing("Updates are disabled in this ad-hoc development build.")
        }
        return team
    }

    private static func verifyPublisher(at url: URL, teamIdentifier: String) throws {
        let requirementText = "anchor apple generic and identifier \"com.geoffrey.assistant\" and certificate leaf[subject.OU] = \"\(teamIdentifier)\""
        var requirement: SecRequirement?
        guard SecRequirementCreateWithString(requirementText as CFString, [], &requirement) == errSecSuccess,
              let requirement else {
            throw GeoffreyUpdaterError.signing("Geoffrey could not prepare its publisher check.")
        }
        var staticCode: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode) == errSecSuccess,
              let staticCode else {
            throw GeoffreyUpdaterError.signing("The downloaded app has no readable code signature.")
        }
        let flags = SecCSFlags(rawValue: kSecCSStrictValidate | kSecCSCheckAllArchitectures)
        guard SecStaticCodeCheckValidity(staticCode, flags, requirement) == errSecSuccess else {
            throw GeoffreyUpdaterError.signing("The downloaded app was not signed by the same Geoffrey publisher.")
        }
    }

    private static func run(_ executable: String, _ arguments: [String]) -> (status: Int32, output: String) {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = output
        do {
            try process.run()
            process.waitUntilExit()
            let data = output.fileHandleForReading.readDataToEndOfFile()
            return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
        } catch {
            return (1, error.localizedDescription)
        }
    }
}
#endif
