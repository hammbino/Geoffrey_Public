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
 printf 'claude\tready\nemail\t2 connected\ngithub\tneeds_setup\nmemory\t%s\napp\tready\n' "$PWD";;
app-prompt)
 printf '%s\n' "$@" > prompt-arguments
 echo 'Controlled test request; do not use real connected tools.';;
app-context)
 printf '%s\n' "$@" > context-arguments
 if [ -f context-fails ]; then echo 'Fixture account reader unavailable'; exit 1; fi
 echo 'PRIVATE GEOFFREY CONTEXT — FRESH_CONNECTED_FIXTURE';;
app-connected-accounts) echo '[{"id":"work","provider":"google","email":"work@example.test"},{"id":"hotmail","provider":"microsoft","email":"home@hotmail.test"}]';;
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
app-item-feedback)
 if [ -f feedback-fails ]; then echo '{"ok":false,"error":"Fixture write failed"}'; exit 1; fi
 shift
 HOME="$PWD" node '__FEEDBACK_SCRIPT__' "$@";;
esac
"""#
        let feedbackScript = FileManager.default.currentDirectoryPath + "/geoffrey-mcp/bin/item-feedback.js"
        try fixture.replacingOccurrences(of: "__FEEDBACK_SCRIPT__", with: feedbackScript).write(to: script, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: script.path)
        let runtime = root.appendingPathComponent("runtime/bin")
        try FileManager.default.createDirectory(at: runtime, withIntermediateDirectories: true)
        let claude = runtime.appendingPathComponent("claude")
        try #"""
#!/bin/bash
cd "$(dirname "$0")/../.."
printf '%s\n' "$@" > claude-arguments
if [ -f claude-fails ]; then
 echo '{"type":"result","is_error":true,"result":"Fixture connection unavailable"}'
 exit 1
fi
if [ -f tool-denied ]; then
 echo '{"type":"result","result":"Unsafe historical fallback","permission_denials":[{"tool_name":"mcp__claude_ai_Gmail__search_threads"}]}'
 exit 0
fi
echo '{"type":"result","result":"Fixture task completed and verified.","session_id":"fixture-action-session"}'
"""#.write(to: claude, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: claude.path)
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
        let privateMemory = root.appendingPathComponent("private-memory")
        try FileManager.default.createDirectory(at: privateMemory.appendingPathComponent("memory"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".geoffrey"), withIntermediateDirectories: true)
        try privateMemory.path.write(to: root.appendingPathComponent(".geoffrey/current-memory"), atomically: true, encoding: .utf8)
        let context = GeoffreyFeedbackContext(responseID: "daily:1000", source: "Your daily briefing", section: "Open loops", item: "Check the supplier refund.")
        let anotherSection = GeoffreyFeedbackContext(responseID: context.responseID, source: context.source, section: "Waiting on", item: context.item)
        expect(context.id != anotherSection.id, "identical prose in separate sections has separate feedback")
        try await model.saveItemFeedback(context, rating: "good", more: true, note: "")
        expect(model.itemFeedback[context.id]?.rating == "good" && model.itemFeedback[context.id]?.more == true, "confirmed local saves publish the correct learning signals")
        let reopened = GeoffreyModel(engine: root.path, restoreSession: false)
        let loaded = try await reopened.loadItemFeedback(context)
        expect(loaded == model.itemFeedback[context.id], "feedback survives reopening with its exact context")
        let unrelated = try await reopened.loadItemFeedback(anotherSection)
        expect(unrelated == nil, "feedback does not leak between sections")
        try await model.saveItemFeedback(context, rating: nil, more: false, note: "Already handled yesterday.")
        expect(model.itemFeedback[context.id]?.rating == nil && model.itemFeedback[context.id]?.note == "Already handled yesterday.", "a note does not require a rating")
        try "".write(to: root.appendingPathComponent("feedback-fails"), atomically: true, encoding: .utf8)
        do {
            try await model.saveItemFeedback(context, rating: "bad", more: false, note: "")
            fatalError("a failed write cannot report success")
        } catch {
            expect(model.itemFeedback[context.id]?.note == "Already handled yesterday.", "failed saves retain previously confirmed feedback")
        }
        try FileManager.default.removeItem(at: root.appendingPathComponent("feedback-fails"))
        try await model.saveItemFeedback(context, rating: nil, more: false, note: "", clear: true)
        expect(model.itemFeedback[context.id] == nil, "clearing feedback removes the saved indicator")
        let cleared = try await reopened.loadItemFeedback(context)
        expect(cleared == nil, "clearing feedback persists")
        model.feedbackBackupTask?.cancel()
        reopened.feedbackBackupTask?.cancel()
        print("Production feedback journeys passed: save, reopen, note-only, failure preservation, clear")

        let briefing = GeoffreyResponse(title: "Your daily briefing", text: "### First action\nReview the supplier refund.", date: Date(), kind: .daily)
        model.latestBriefing = briefing
        model.performBriefingAction("Review the supplier refund.", from: briefing)
        expect(model.selectedSection == .ask && model.isRunning, "Start here opens the conversation and begins work")
        let messageCount = model.conversation.count
        model.performBriefingAction("Another task", from: briefing)
        expect(model.conversation.count == messageCount, "a second click cannot start duplicate work")
        try await wait { !model.isRunning }
        let promptArguments = try String(contentsOf: root.appendingPathComponent("prompt-arguments"), encoding: .utf8)
        let actionArguments = try String(contentsOf: root.appendingPathComponent("claude-arguments"), encoding: .utf8)
        expect(promptArguments.contains("briefing-action") && promptArguments.contains("Selected action:\nReview the supplier refund.") && promptArguments.contains(briefing.text), "the exact selected task and briefing context reach the runner")
        expect(!actionArguments.contains("--permission-mode") && !actionArguments.contains("--resume"), "a selected action starts a fresh task with normal tool checks")
        expect(model.conversation.last?.text == "Fixture task completed and verified." && model.latestBriefing?.date == briefing.date, "the task result appears in chat while preserving the briefing")
        model.run(task: .ask("Use the revised invoice number."))
        try await wait { !model.isRunning }
        let followUpArguments = try String(contentsOf: root.appendingPathComponent("claude-arguments"), encoding: .utf8)
        expect(followUpArguments.contains("--resume\nfixture-action-session\n") && !followUpArguments.contains("--permission-mode"), "answers to task questions continue the action session with normal tool checks")
        expect(followUpArguments.contains("FRESH_CONNECTED_FIXTURE") && followUpArguments.contains("TODAY'S LOCAL DATE:"), "chat receives fresh account context and the current local clock")
        expect(followUpArguments.contains("--mcp-config\n") && followUpArguments.contains("\"GEOFFREY_READ_ONLY\":\"1\""), "chat uses an isolated read-only account server")
        expect(followUpArguments.contains("--strict-mcp-config") && followUpArguments.contains("AUTHORITATIVE GEOFFREY CONNECTIONS") && followUpArguments.contains("home@hotmail.test"), "chat excludes separate Claude connectors and gets the current Microsoft account registry")
        expect(followUpArguments.contains("mcp__geoffrey_readonly__search_messages") && !followUpArguments.contains("--dangerously-skip-permissions") && !GeoffreyReadOnlyConnection.toolNames.contains(where: { $0.contains("modify") || $0.contains("draft") || $0.contains("*") }), "only explicit reading tools are allowed without further approval")
        let contextArguments = try String(contentsOf: root.appendingPathComponent("context-arguments"), encoding: .utf8)
        expect(contextArguments.contains("--task\nask"), "Ask Geoffrey prepares live context through the connected-account reader")
        try "".write(to: root.appendingPathComponent("claude-fails"), atomically: true, encoding: .utf8)
        model.performBriefingAction("Review the supplier refund.", from: briefing)
        try await wait { !model.isRunning }
        expect(model.showingIssue && model.canRetryLastRequest, "an action failure exposes the existing retry flow")
        let failedMessageCount = model.conversation.count
        try FileManager.default.removeItem(at: root.appendingPathComponent("claude-fails"))
        model.retryLastRequest()
        try await wait { !model.isRunning }
        expect(model.conversation.count == failedMessageCount + 1 && model.conversation.last?.isOwner == false, "retrying adds the result without duplicating the owner's action request")
        model.startNewConversation()
        model.run(task: .ask("Plan tomorrow."))
        try await wait { !model.isRunning }
        let newArguments = try String(contentsOf: root.appendingPathComponent("claude-arguments"), encoding: .utf8)
        expect(newArguments.contains("--permission-mode\nplan\n") && !newArguments.contains("--resume"), "a new conversation resets the action session")
        print("Start here journeys passed: task handoff, duplicate guard, result, follow-up, failure, retry, reset")
        try "".write(to: root.appendingPathComponent("context-fails"), atomically: true, encoding: .utf8)
        model.run(task: .ask("What follow-ups need attention today?"))
        try await wait { !model.isRunning }
        let unavailableArguments = try String(contentsOf: root.appendingPathComponent("claude-arguments"), encoding: .utf8)
        expect(unavailableArguments.contains("Email status and today's schedule are unverified") && unavailableArguments.contains("Do not assert pending replies"), "failed snapshots cannot turn old briefings into current email facts")
        try "".write(to: root.appendingPathComponent("tool-denied"), atomically: true, encoding: .utf8)
        let beforeDenial = model.conversation.count
        model.run(task: .ask("Check email again."))
        try await wait { !model.isRunning }
        expect(model.conversation.count == beforeDenial + 1 && model.conversation.last?.text != "Unsafe historical fallback", "tool denial cannot publish a misleading fallback as a successful answer")
        expect(model.issueMessage.contains("tool-permission problem") && model.canRetryLastRequest, "a blocked tool is reported separately from account sign-in failure with retry")
        try FileManager.default.removeItem(at: root.appendingPathComponent("tool-denied"))
        let skillPath = root.appendingPathComponent("SKILL.md")
        try "# Selected skill\nProvide the fixture review.".write(to: skillPath, atomically: true, encoding: .utf8)
        let selectedCapability = GeoffreyCapability(id: "skill:fixture", name: "fixture", type: "skill", source: "Geoffrey", enabled: true, state: "ready", repair: nil, description: "Fixture skill", path: skillPath.path)
        model.runCapability(selectedCapability, request: "Review my launch plan")
        expect(model.selectedSection == .ask && model.isRunning, "Run capability opens chat and starts the selected task")
        try await wait { !model.isRunning }
        let capabilityArguments = try String(contentsOf: root.appendingPathComponent("claude-arguments"), encoding: .utf8)
        let capabilityPrompt = try String(contentsOf: root.appendingPathComponent("prompt-arguments"), encoding: .utf8)
        expect(capabilityPrompt.contains("skill:fixture") && capabilityPrompt.contains("Provide the fixture review") && capabilityPrompt.contains("Review my launch plan"), "the exact capability, loaded instructions, and requested result reach prompt preparation")
        expect(model.conversation.suffix(2).first?.text == "Use Fixture:\n\nReview my launch plan", "capability task messages show the requested outcome without internal paths or instructions")
        expect(!capabilityArguments.contains("--resume") && !capabilityArguments.contains("--strict-mcp-config"), "selected capabilities start fresh and retain installed plugin connections")
        expect(!capabilityArguments.contains("--permission-mode"), "running a selected capability uses normal action permission checks")
        try FileManager.default.removeItem(at: skillPath)
        let beforeMissingSkill = model.conversation.count
        model.runCapability(selectedCapability, request: "Run missing instructions")
        expect(!model.isRunning && model.conversation.count == beforeMissingSkill && model.showingIssue, "missing skill instructions cannot run an unrelated fallback")
        print("Chat email journeys passed: fresh context, current date, read-only tools, failed reads, permission denial")
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
