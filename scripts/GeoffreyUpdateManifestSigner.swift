import CryptoKit
import Foundation

struct ArchiveRecord: Codable {
    let url: String
    let sha256: String
    let bytes: Int64
}

struct Payload: Codable {
    let schemaVersion: Int
    let version: String
    let build: Int
    let publishedAt: String
    let minimumMacOS: String
    let releaseNotes: String
    let archive: ArchiveRecord

    enum CodingKeys: String, CodingKey {
        case version, build, archive
        case schemaVersion = "schema_version"
        case publishedAt = "published_at"
        case minimumMacOS = "minimum_macos"
        case releaseNotes = "release_notes"
    }
}

struct Envelope: Codable {
    let payload: String
    let signature: String
}

func options(_ arguments: [String]) -> [String: String] {
    var result = [String: String]()
    var index = 0
    while index + 1 < arguments.count {
        result[arguments[index]] = arguments[index + 1]
        index += 2
    }
    return result
}

func sha256(_ url: URL) throws -> String {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var hasher = SHA256()
    while true {
        let data = try handle.read(upToCount: 1_048_576) ?? Data()
        if data.isEmpty { break }
        hasher.update(data: data)
    }
    return hasher.finalize().map { String(format: "%02x", $0) }.joined()
}

@main
struct GeoffreyUpdateManifestSigner {
    static func main() throws {
        let values = options(Array(CommandLine.arguments.dropFirst()))
        guard let archivePath = values["--archive"],
              let archiveURL = values["--archive-url"],
              let notesPath = values["--notes"],
              let privateKeyPath = values["--private-key"],
              let outputPath = values["--output"],
              let version = values["--version"],
              let buildText = values["--build"], let build = Int(buildText),
              let minimumMacOS = values["--minimum-macos"] else {
            throw NSError(domain: "GeoffreyRelease", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing manifest signer argument."])
        }

        let manager = FileManager.default
        let keyAttributes = try manager.attributesOfItem(atPath: privateKeyPath)
        let permissions = (keyAttributes[.posixPermissions] as? NSNumber)?.intValue ?? 0o777
        guard permissions & 0o077 == 0 else {
            throw NSError(domain: "GeoffreyRelease", code: 3, userInfo: [NSLocalizedDescriptionKey: "The update private key must not be readable by group or other users."])
        }
        let keyText = try String(contentsOfFile: privateKeyPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let keyData = Data(base64Encoded: keyText), keyData.count == 32 else {
            throw NSError(domain: "GeoffreyRelease", code: 4, userInfo: [NSLocalizedDescriptionKey: "The update private key is not a 32-byte base64 Ed25519 key."])
        }
        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
        let archiveFile = URL(fileURLWithPath: archivePath)
        let attributes = try manager.attributesOfItem(atPath: archivePath)
        let bytes = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        let notes = try String(contentsOfFile: notesPath, encoding: .utf8)
        let publishedAt = values["--published-at"] ?? ISO8601DateFormatter().string(from: Date())
        let payload = Payload(
            schemaVersion: 1,
            version: version,
            build: build,
            publishedAt: publishedAt,
            minimumMacOS: minimumMacOS,
            releaseNotes: notes,
            archive: ArchiveRecord(url: archiveURL, sha256: try sha256(archiveFile), bytes: bytes)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let payloadData = try encoder.encode(payload)
        let signature = try privateKey.signature(for: payloadData)
        let envelope = Envelope(payload: payloadData.base64EncodedString(), signature: signature.base64EncodedString())
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var output = try encoder.encode(envelope)
        output.append(0x0A)
        try output.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
        print("Signed Geoffrey \(version) build \(build) update manifest.")
    }
}
