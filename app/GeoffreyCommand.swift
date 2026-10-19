import Foundation
import Darwin

struct CommandResult: Sendable {
    let status: Int32
    let output: String
    let standardError: String
}

/// Non-streaming commands write to private files: neither output stream can fill
/// a pipe while we wait. The same runner handles deadlines and cancellation.
final class GeoffreyCommand: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    func cancel() {
        lock.lock(); cancelled = true; lock.unlock()
    }

    private var isCancelled: Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelled
    }

    static func environment(engine: String? = nil) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let bundled = engine.map { $0 + "/runtime/bin:" } ?? ""
        env["PATH"] = bundled + home + "/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        if let engine, FileManager.default.isDirectory(atPath: engine + "/runtime/git-core") {
            env["GIT_EXEC_PATH"] = engine + "/runtime/git-core"
            env["GIT_TEMPLATE_DIR"] = engine + "/runtime/git-template"
        }
        return env
    }

    func run(executable: String, arguments: [String], workingDirectory: String? = nil,
             environment: [String: String]? = nil, timeout: TimeInterval = 120) -> CommandResult {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("geoffrey-command-" + UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            defer { try? FileManager.default.removeItem(at: directory) }
            let stdoutURL = directory.appendingPathComponent("stdout")
            let stderrURL = directory.appendingPathComponent("stderr")
            for url in [stdoutURL, stderrURL] {
                guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [.posixPermissions: 0o600]) else {
                    throw CocoaError(.fileWriteUnknown)
                }
            }
            let stdout = try FileHandle(forWritingTo: stdoutURL)
            let stderr = try FileHandle(forWritingTo: stderrURL)
            defer { try? stdout.close(); try? stderr.close() }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            process.currentDirectoryURL = workingDirectory.map { URL(fileURLWithPath: $0) }
            process.environment = environment ?? Self.environment()
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = stdout
            process.standardError = stderr
            if isCancelled { return CommandResult(status: 130, output: "Cancelled", standardError: "") }
            try process.run()
            let deadline = ProcessInfo.processInfo.systemUptime + timeout
            var forcedStatus: Int32?
            while process.isRunning {
                if isCancelled || ProcessInfo.processInfo.systemUptime >= deadline {
                    forcedStatus = isCancelled ? 130 : 124
                    process.terminate()
                    let grace = ProcessInfo.processInfo.systemUptime + 0.5
                    while process.isRunning && ProcessInfo.processInfo.systemUptime < grace { Thread.sleep(forTimeInterval: 0.01) }
                    if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                    break
                }
                Thread.sleep(forTimeInterval: 0.01)
            }
            process.waitUntilExit()
            let standard = String(decoding: try Data(contentsOf: stdoutURL), as: UTF8.self)
            let errors = String(decoding: try Data(contentsOf: stderrURL), as: UTF8.self)
            return CommandResult(status: forcedStatus ?? process.terminationStatus,
                                 output: standard.isEmpty ? errors : standard, standardError: errors)
        } catch {
            return CommandResult(status: 1, output: error.localizedDescription, standardError: error.localizedDescription)
        }
    }
}

private extension FileManager {
    func isDirectory(atPath path: String) -> Bool {
        var directory: ObjCBool = false
        return fileExists(atPath: path, isDirectory: &directory) && directory.boolValue
    }
}
