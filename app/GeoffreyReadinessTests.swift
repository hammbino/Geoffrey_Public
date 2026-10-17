import Foundation

@main
struct GeoffreyReadinessTests {
    static func main() {
        let ready = GeoffreyReadiness.items(
            health: ["claude": "ready", "github": "ready", "memory": "/private/memory"],
            accountCount: 2,
            accountsNeedingRepair: 0,
            capabilityCount: 8,
            capabilitiesNeedingRepair: 0
        )
        expect(ready.count == 5 && ready.allSatisfy { $0.state == .ready }, "all-ready state")
        expect(ready.first(where: { $0.id == "email" })?.detail.contains("2 accounts") == true, "multi-account summary")

        let repair = GeoffreyReadiness.items(
            health: ["claude": "needs_login", "github": "needs_setup", "memory": "needs_setup"],
            accountCount: 2,
            accountsNeedingRepair: 1,
            capabilityCount: 4,
            capabilitiesNeedingRepair: 2
        )
        expect(repair.allSatisfy { $0.state == .needsAttention }, "attention states")
        expect(repair.first(where: { $0.id == "claude" })?.actionTitle == "Sign in", "Claude repair action")
        expect(repair.first(where: { $0.id == "email" })?.actionTitle == "Review", "account repair action")
        expect(repair.first(where: { $0.id == "github" })?.actionTitle == "Connect", "GitHub repair action")
        expect(repair.first(where: { $0.id == "capabilities" })?.detail.contains("2 Claude capabilities") == true, "capability repair count")

        let empty = GeoffreyReadiness.items(
            health: ["claude": "needs_setup"],
            accountCount: 0,
            accountsNeedingRepair: 0,
            capabilityCount: 0,
            capabilitiesNeedingRepair: 0
        )
        expect(empty.first(where: { $0.id == "email" })?.actionTitle == "Add account", "first account action")
        expect(empty.first(where: { $0.id == "capabilities" })?.detail.contains("could not inventory") == true, "empty inventory explanation")

        let status = "claude\tready\nemail\t2 connected\ngithub\tready\nmemory\t/private/memory\napp\tready\n"
        expect(GeoffreyReadinessRefresh.health(output: status, status: 0)?["memory"] == "/private/memory", "complete health contract")
        for (output, exitStatus) in [(status, Int32(1)), (status, Int32(124)), ("", Int32(0)), ("claude\tready", Int32(0)), (status + "claude\tneeds_login\n", Int32(0))] {
            expect(GeoffreyReadinessRefresh.health(output: output, status: exitStatus) == nil, "failed or partial health must not replace saved setup")
        }
        let capabilityJSON = "[{\"id\":\"skill:test\",\"name\":\"test\",\"type\":\"skill\",\"source\":\"Claude\",\"enabled\":true,\"state\":\"ready\",\"description\":\"Test\"}]"
        expect(GeoffreyReadinessRefresh.capabilities(output: capabilityJSON, status: 0)?.first?.id == "skill:test", "real capability contract decodes")
        expect(GeoffreyReadinessRefresh.capabilities(output: "[]", status: 0)?.isEmpty == true, "successful empty capability check is distinct from failure")
        for (output, exitStatus) in [("invalid", Int32(0)), (capabilityJSON, Int32(1)), (capabilityJSON, Int32(124)), ("{}", Int32(0))] {
            expect(GeoffreyReadinessRefresh.capabilities(output: output, status: exitStatus) == nil, "failed inventory must preserve last known capabilities")
        }
        expect(GeoffreyReadinessRefresh.issue(status: 124, subject: "setup").contains("too long"), "setup timeout guidance")
        expect(GeoffreyReadinessRefresh.issue(status: 1, subject: "skills").contains("last successful check"), "stale readiness explained")

        print("Geoffrey readiness tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
