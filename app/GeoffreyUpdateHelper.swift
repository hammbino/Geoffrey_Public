import Foundation
import Security

struct Arguments {
    let operation: String
    let current: URL
    let candidate: URL
    let backup: URL
    let pid: pid_t
    let bundleID: String
    let teamID: String
    let version: String?
    let build: Int?

    init?(_ values: [String]) {
        guard let operation = values.first, operation == "install" || operation == "rollback" else { return nil }
        var options = [String: String]()
        var index = 1
        while index + 1 < values.count {
            options[values[index]] = values[index + 1]
            index += 2
        }
        guard let current = options["--current"],
              let candidate = options["--candidate"],
              let backup = options["--backup"],
              let rawPID = options["--pid"], let pid = pid_t(rawPID),
              let bundleID = options["--bundle-id"],
              let teamID = options["--team-id"], !teamID.isEmpty else { return nil }
        self.operation = operation
        self.current = URL(fileURLWithPath: current).standardizedFileURL
        self.candidate = URL(fileURLWithPath: candidate).standardizedFileURL
        self.backup = URL(fileURLWithPath: backup).standardizedFileURL
        self.pid = pid
        self.bundleID = bundleID
        self.teamID = teamID
        self.version = options["--version"]
        self.build = options["--build"].flatMap(Int.init)
    }
}

func verifyApp(_ url: URL, arguments: Arguments) throws {
    guard url.pathExtension == "app", let bundle = Bundle(url: url), bundle.bundleIdentifier == arguments.bundleID else {
        throw NSError(domain: "GeoffreyUpdate", code: 10, userInfo: [NSLocalizedDescriptionKey: "Unexpected application bundle."])
    }
    if arguments.operation == "install" {
        guard bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String == arguments.version,
              Int(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") == arguments.build else {
            throw NSError(domain: "GeoffreyUpdate", code: 11, userInfo: [NSLocalizedDescriptionKey: "Update version changed after verification."])
        }
    }
    let requirementText = "anchor apple generic and identifier \"\(arguments.bundleID)\" and certificate leaf[subject.OU] = \"\(arguments.teamID)\""
    var requirement: SecRequirement?
    var code: SecStaticCode?
    guard SecRequirementCreateWithString(requirementText as CFString, [], &requirement) == errSecSuccess,
          SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess,
          let requirement, let code,
          SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate | kSecCSCheckAllArchitectures), requirement) == errSecSuccess else {
        throw NSError(domain: "GeoffreyUpdate", code: 12, userInfo: [NSLocalizedDescriptionKey: "Publisher verification failed."])
    }
}

func waitForExit(_ pid: pid_t) throws {
    for _ in 0..<300 {
        if kill(pid, 0) != 0 { return }
        Thread.sleep(forTimeInterval: 0.1)
    }
    throw NSError(domain: "GeoffreyUpdate", code: 20, userInfo: [NSLocalizedDescriptionKey: "Geoffrey did not close in time."])
}

func install(_ arguments: Arguments) throws {
    let manager = FileManager.default
    guard arguments.current.lastPathComponent == "Geoffrey.app",
          arguments.candidate.lastPathComponent == "Geoffrey.app",
          arguments.backup.lastPathComponent.hasPrefix("Geoffrey") else {
        throw NSError(domain: "GeoffreyUpdate", code: 30, userInfo: [NSLocalizedDescriptionKey: "Unsafe update destination."])
    }
    try verifyApp(arguments.candidate, arguments: arguments)
    try waitForExit(arguments.pid)
    try manager.createDirectory(at: arguments.backup.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    if manager.fileExists(atPath: arguments.backup.path) { try manager.removeItem(at: arguments.backup) }
    try manager.moveItem(at: arguments.current, to: arguments.backup)
    do {
        try manager.moveItem(at: arguments.candidate, to: arguments.current)
        try verifyApp(arguments.current, arguments: arguments)
    } catch {
        if manager.fileExists(atPath: arguments.current.path) { try? manager.removeItem(at: arguments.current) }
        try? manager.moveItem(at: arguments.backup, to: arguments.current)
        throw error
    }
    let launcher = Process()
    launcher.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    launcher.arguments = [arguments.current.path]
    try launcher.run()
}

func recordFailure(_ error: Error, arguments: Arguments) {
    let manager = FileManager.default
    let state = arguments.backup.deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("last-update-error.txt")
    try? manager.createDirectory(at: state.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    try? (error.localizedDescription + "\n").write(to: state, atomically: true, encoding: .utf8)
    try? manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: state.path)
    if manager.fileExists(atPath: arguments.current.path) {
        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        launcher.arguments = [arguments.current.path]
        try? launcher.run()
    }
}

guard let arguments = Arguments(Array(CommandLine.arguments.dropFirst())) else {
    FileHandle.standardError.write(Data("Invalid Geoffrey update-helper arguments.\n".utf8))
    exit(2)
}

do {
    try install(arguments)
} catch {
    recordFailure(error, arguments: arguments)
    FileHandle.standardError.write(Data("Geoffrey update failed safely: \(error.localizedDescription)\n".utf8))
    exit(1)
}
