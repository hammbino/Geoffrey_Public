import Foundation

@main
struct GeoffreyAutomationsTests {
    static func main() throws {
        let data = Data("""
        {
          "schema_version": 1,
          "execution_available": false,
          "source": "memory/automations/manifest.json",
          "workflows": [{
            "id": "social-briefing",
            "name": "Social briefing",
            "purpose": "Prepare the briefing",
            "task": null,
            "enabled": false,
            "cadence": {"summary": "Daily at 08:00, 13:00, 17:00", "timezone": "America/Denver", "times": ["08:00", "13:00", "17:00"]},
            "execution": {"route": "cloud", "preference": "cloud", "reason": "Cloud safe", "deployment_state": "not_connected", "verified_at": null, "routine_url": null, "result_branch": "claude/geoffrey-results-social-briefing-test", "verification_method": null, "verification_run_url": null, "missing_capabilities": [], "can_run": false},
            "approval": {"state": "needs_review", "approved_at": null},
            "source": {"kind": "legacy_memory", "path": "memory/social-briefing.md"},
            "result_destination": "private_memory",
            "status": {"state": "needs_review", "last_run_at": null, "last_run_status": null, "next_run_at": null, "queued_runs": 0, "failed_runs": 0, "last_result_path": null, "last_error": null}
          }],
          "summary": {"total": 1, "cloud": 1, "local": 0, "needs_review": 1, "queued_runs": 0, "failed_runs": 0}
        }
        """.utf8)
        let inventory = try JSONDecoder().decode(GeoffreyAutomationInventory.self, from: data)
        expect(inventory.workflows.first?.routePresentation.title == "Cloud capable", "unconnected cloud label")
        expect(inventory.summary.needsReview == 1, "review count")
        expect(inventory.workflows.first?.cadence.times.count == 3, "editable schedule times")
        expect(inventory.workflows.first?.execution.resultBranch == "claude/geoffrey-results-social-briefing-test", "cloud result branch contract")

        let request = GeoffreyAutomationSaveRequest(
            id: "social-briefing",
            name: "Social briefing",
            purpose: "Prepare the briefing",
            task: "Review connected sources.",
            route: "cloud",
            timezone: "America/Denver",
            times: ["08:00"],
            resultDestination: "private_memory",
            approved: true,
            source: GeoffreyAutomationSource(kind: "user_created", path: nil)
        )
        let requestObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        expect(requestObject?["result_destination"] as? String == "private_memory", "portable save contract")

        let active = GeoffreyAutomationRoutePresentation(route: "cloud", deploymentState: "active", approvalState: "approved")
        expect(active.title == "Cloud run reviewed", "active cloud label")
        let connected = GeoffreyAutomationRoutePresentation(route: "cloud", deploymentState: "connected", approvalState: "approved")
        expect(connected.title == "Cloud setup recorded", "connected cloud label")
        let local = GeoffreyAutomationRoutePresentation(route: "local", deploymentState: "not_connected", approvalState: "approved")
        expect(local.title == "Runs when this Mac is available", "local label")
        let review = GeoffreyAutomationRoutePresentation(route: "review", deploymentState: "not_connected", approvalState: "needs_review")
        expect(review.title == "Needs review", "review label")
        print("Geoffrey automation tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
