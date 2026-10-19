import Foundation

@main struct GeoffreyModelTests {
    @MainActor static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("geoffrey-model-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent("bin"), withIntermediateDirectories: true)
        let script = root.appendingPathComponent("bin/geoffrey")
        let fixture = #"""
#!/bin/bash
cd "$(dirname "$0")/.."
echo "$1" >> calls
case "$1" in
app-migrate) echo '{}';;
app-status)
 printf 'claude\tready\nemail\t2 connected\ngithub\tneeds_setup\nmemory\t/private/fixture\napp\tready\n';;
app-accounts)
 if [ -f failed ]; then exit 1; fi
 echo '[{"id":"work","email":"work@example.test","provider":"google","purpose":"","duplicate_count":1,"credential_state":"ready","mail":{"state":"ready","detail":""},"calendar":{"state":"ready","detail":""}},{"id":"home","email":"home@example.test","provider":"microsoft","purpose":"","duplicate_count":1,"credential_state":"ready","mail":{"state":"ready","detail":""},"calendar":{"state":"ready","detail":""}}]';;
app-automation-queue) echo '{}';;
app-capabilities) sleep 3; echo '[]';;
app-automations) echo '{"schema_version":1,"execution_available":false,"workflows":[]}';;
app-sync-status) echo '{"state":"local_only","ahead":0,"behind":0,"dirty":false,"message":"Local memory"}';;
app-portable-state) exit 1;;
app-add-account) sleep 1; exit 0;;
app-login-claude) exit 0;;
esac
"""#
        try fixture.write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: script.path)
        let model = GeoffreyModel(engine: root.path, restoreSession: false)
        let start = Date()
        model.refresh()
        try await wait { !model.isRefreshingAccounts }
        expect(Date().timeIntervalSince(start) < 2.5, "optional capability work cannot hold setup results")
        expect(model.accounts.count == 2 && model.isReady, "multiple providers and local memory complete setup without GitHub")
        expect(model.health["github"] == "needs_setup", "optional backup stays honestly unconnected")
        try "".write(to: root.appendingPathComponent("failed"), atomically: true, encoding: .utf8)
        model.refresh()
        model.refresh() // request arriving while a check is active must be retained
        try await wait { !model.isRefreshingAccounts }
        expect(model.accounts.count == 2 && model.connectionRefreshIssue != nil, "failed refresh preserves every connected account")
        let calls = try String(contentsOf: root.appendingPathComponent("calls"), encoding: .utf8)
        expect(calls.components(separatedBy: "app-migrate").count == 2, "migration runs once after success")
        model.beginAccountConnection(provider: "google")
        model.cancelAccountConnection()
        try await Task.sleep(for: .milliseconds(200))
        expect(!model.isConnectingAccount && model.accountConnectionOutcome == nil, "cancelled sign-in cannot report success")
        model.beginAccountConnection(provider: "microsoft")
        try await wait { !model.isConnectingAccount }
        expect(!model.accountConnectionFailed && model.accountConnectionOutcome != nil, "another account can be connected after cancellation")
        model.openClaudeLogin()
        try await wait { !model.isSigningIntoClaude }
        expect(model.health["claude"] == "ready" && !model.showingIssue, "successful login does not display an error")
        // Let the optional fixture processes finish before removing their directory.
        try await Task.sleep(for: .seconds(4))
        print("Production app model setup journeys passed")
    }
    @MainActor static func wait(_ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(8)
        while !condition() && Date() < deadline { try await Task.sleep(for: .milliseconds(20)) }
        expect(condition(), "model transition finished before deadline")
    }
    static func expect(_ condition: Bool, _ message: String) {
        if !condition { fatalError(message) }
    }
}
