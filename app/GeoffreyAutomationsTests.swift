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
            "enabled": false,
            "cadence": {"summary": "Daily at 08:00, 13:00, 17:00", "timezone": "America/Denver"},
            "execution": {"route": "cloud", "reason": "Cloud safe", "deployment_state": "not_connected", "missing_capabilities": []},
            "approval": {"state": "needs_review"},
            "source": {"kind": "legacy_memory", "path": "memory/social-briefing.md"},
            "status": {"state": "needs_review", "last_run_at": null, "next_run_at": null, "queued_runs": 0, "last_error": null}
          }],
          "summary": {"total": 1, "cloud": 1, "local": 0, "needs_review": 1, "queued_runs": 0}
        }
        """.utf8)
        let inventory = try JSONDecoder().decode(GeoffreyAutomationInventory.self, from: data)
        expect(inventory.workflows.first?.routePresentation.title == "Cloud capable", "unconnected cloud label")
        expect(inventory.summary.needsReview == 1, "review count")

        let active = GeoffreyAutomationRoutePresentation(route: "cloud", deploymentState: "active", approvalState: "approved")
        expect(active.title == "Runs in Claude cloud", "active cloud label")
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
