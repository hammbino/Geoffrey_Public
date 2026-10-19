import Foundation

@main struct GeoffreyCommandTests {
    static func main() {
        let runner = GeoffreyCommand()
        expect(GeoffreyCommand.environment()["TZ"] == TimeZone.current.identifier, "child commands use the owner's macOS time zone")
        let large = runner.run(executable: "/bin/sh", arguments: ["-c", "head -c 1048576 /dev/zero; head -c 1048576 /dev/zero >&2"], timeout: 5)
        expect(large.status == 0 && large.output.utf8.count == 1048576 && large.standardError.utf8.count == 1048576, "large stdout and stderr finish without deadlock")
        let failure = runner.run(executable: "/bin/sh", arguments: ["-c", "echo partial; echo explanation >&2; exit 7"])
        expect(failure.status == 7 && failure.output == "partial\n" && failure.standardError == "explanation\n", "preserves both streams and exit status")
        let start = Date()
        let timeout = runner.run(executable: "/bin/sh", arguments: ["-c", "trap '' TERM; while :; do :; done"], timeout: 0.1)
        expect(timeout.status == 124 && Date().timeIntervalSince(start) < 3, "deadline kills a resistant child")
        let cancelled = GeoffreyCommand()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { cancelled.cancel() }
        let result = cancelled.run(executable: "/bin/sh", arguments: ["-c", "trap '' TERM; while :; do :; done"], timeout: 10)
        expect(result.status == 130, "active command cancels")
        let beforeLaunch = GeoffreyCommand(); beforeLaunch.cancel()
        expect(beforeLaunch.run(executable: "/usr/bin/false", arguments: []).status == 130, "cancel before launch cannot start work")
        expect(runner.run(executable: "/does-not-exist", arguments: []).status == 1, "launch failure returns a result")
        print("Production command runner tests passed")
    }
    static func expect(_ value: Bool, _ message: String) {
        if !value { fatalError(message) }
    }
}
