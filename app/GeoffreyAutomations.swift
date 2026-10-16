import Foundation
#if !AUTOMATION_LOGIC_ONLY
import SwiftUI
#endif

struct GeoffreyAutomationInventory: Codable {
    let schemaVersion: Int
    let executionAvailable: Bool
    let source: String?
    let workflows: [GeoffreyAutomation]
    let summary: GeoffreyAutomationSummary

    enum CodingKeys: String, CodingKey {
        case source, workflows, summary
        case schemaVersion = "schema_version"
        case executionAvailable = "execution_available"
    }

    static let empty = GeoffreyAutomationInventory(
        schemaVersion: 1,
        executionAvailable: false,
        source: nil,
        workflows: [],
        summary: GeoffreyAutomationSummary(total: 0, cloud: 0, local: 0, needsReview: 0, queuedRuns: 0, failedRuns: 0)
    )
}

struct GeoffreyAutomationSummary: Codable {
    let total: Int
    let cloud: Int
    let local: Int
    let needsReview: Int
    let queuedRuns: Int
    let failedRuns: Int

    enum CodingKeys: String, CodingKey {
        case total, cloud, local
        case needsReview = "needs_review"
        case queuedRuns = "queued_runs"
        case failedRuns = "failed_runs"
    }
}

struct GeoffreyAutomation: Codable, Identifiable {
    let id: String
    let name: String
    let purpose: String
    let enabled: Bool
    let cadence: GeoffreyAutomationCadence
    let execution: GeoffreyAutomationExecution
    let approval: GeoffreyAutomationApproval
    let source: GeoffreyAutomationSource
    let status: GeoffreyAutomationStatus

    var routePresentation: GeoffreyAutomationRoutePresentation {
        GeoffreyAutomationRoutePresentation(
            route: execution.route,
            deploymentState: execution.deploymentState,
            approvalState: approval.state
        )
    }
}

struct GeoffreyAutomationCadence: Codable {
    let summary: String
    let timezone: String?
}

struct GeoffreyAutomationExecution: Codable {
    let route: String
    let reason: String
    let deploymentState: String
    let verifiedAt: String?
    let missingCapabilities: [String]
    let canRun: Bool

    enum CodingKeys: String, CodingKey {
        case route, reason
        case deploymentState = "deployment_state"
        case verifiedAt = "verified_at"
        case missingCapabilities = "missing_capabilities"
        case canRun = "can_run"
    }
}

struct GeoffreyAutomationApproval: Codable {
    let state: String
}

struct GeoffreyAutomationSource: Codable {
    let kind: String
    let path: String?
}

struct GeoffreyAutomationStatus: Codable {
    let state: String
    let lastRunAt: String?
    let lastRunStatus: String?
    let nextRunAt: String?
    let queuedRuns: Int
    let failedRuns: Int
    let lastResultPath: String?
    let lastError: String?

    enum CodingKeys: String, CodingKey {
        case state
        case lastRunAt = "last_run_at"
        case lastRunStatus = "last_run_status"
        case nextRunAt = "next_run_at"
        case queuedRuns = "queued_runs"
        case failedRuns = "failed_runs"
        case lastResultPath = "last_result_path"
        case lastError = "last_error"
    }
}

struct GeoffreyAutomationRoutePresentation {
    let title: String
    let icon: String
    let colorName: String

    init(route: String, deploymentState: String, approvalState: String) {
        switch route {
        case "cloud":
            title = deploymentState == "active" && approvalState == "approved" ? "Runs in Claude cloud" : "Cloud capable"
            icon = "cloud.fill"
            colorName = "blue"
        case "local":
            title = "Runs when this Mac is available"
            icon = "desktopcomputer"
            colorName = "purple"
        default:
            title = "Needs review"
            icon = "checklist"
            colorName = "orange"
        }
    }
}

#if !AUTOMATION_LOGIC_ONLY
private extension GeoffreyAutomationRoutePresentation {
    var color: Color {
        switch colorName {
        case "blue": return .blue
        case "purple": return .purple
        default: return .orange
        }
    }
}

struct AutomationCenterView: View {
    @EnvironmentObject private var model: GeoffreyModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Automations")
                            .font(.system(size: 30, weight: .semibold))
                        Text("Keep recurring work in one place and see whether it can run in Claude’s cloud or needs this Mac.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 740, alignment: .leading)
                    }
                    Spacer()
                    Button { model.refresh() } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 12) {
                    AutomationMetric(value: model.automationInventory.summary.total, label: "Found", icon: "repeat")
                    AutomationMetric(value: model.automationInventory.summary.cloud, label: "Cloud capable", icon: "cloud.fill")
                    AutomationMetric(value: model.automationInventory.summary.local, label: "Mac required", icon: "desktopcomputer")
                    AutomationMetric(value: model.automationInventory.summary.queuedRuns, label: "Queued", icon: "clock.arrow.circlepath")
                }

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(Color(red: 0.08, green: 0.45, blue: 0.36))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Review before Geoffrey changes a schedule").font(.headline)
                        Text("Imported work stays off until its timing, tools, and destination are approved. Geoffrey will not duplicate an existing briefing or silently create a cloud schedule.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .background(Color(red: 0.08, green: 0.45, blue: 0.36).opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if model.automations.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No recurring work found on this Mac").font(.title3.weight(.semibold))
                        Text("When an existing Geoffrey installation updates, Geoffrey will look in private memory for briefings, routines, and schedules. Any imported item will appear here for review before Geoffrey changes it.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 650, alignment: .leading)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    if model.automationInventory.summary.failedRuns > 0 {
                        Label("\(model.automationInventory.summary.failedRuns) run\(model.automationInventory.summary.failedRuns == 1 ? "" : "s") need a retry", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recurring work").font(.headline)
                        ForEach(model.automations) { automation in
                            AutomationCard(automation: automation)
                        }
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 980, alignment: .leading)
        }
    }
}

private struct AutomationMetric: View {
    let value: Int
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Color(red: 0.08, green: 0.45, blue: 0.36))
            VStack(alignment: .leading, spacing: 1) {
                Text("\(value)").font(.title3.weight(.semibold))
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct AutomationCard: View {
    @EnvironmentObject private var model: GeoffreyModel
    let automation: GeoffreyAutomation

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: automation.routePresentation.icon)
                    .font(.title3)
                    .foregroundStyle(automation.routePresentation.color)
                    .frame(width: 26)
                VStack(alignment: .leading, spacing: 4) {
                    Text(automation.name).font(.title3.weight(.semibold))
                    Text(automation.purpose).foregroundStyle(.secondary)
                }
                Spacer(minLength: 16)
                Label(automation.routePresentation.title, systemImage: automation.routePresentation.icon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(automation.routePresentation.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(automation.routePresentation.color.opacity(0.10))
                    .clipShape(Capsule())
            }

            HStack(spacing: 18) {
                Label(automation.cadence.summary, systemImage: "calendar.badge.clock")
                if let timezone = automation.cadence.timezone {
                    Label(timezone, systemImage: "globe.americas")
                }
                if automation.status.queuedRuns > 0 {
                    Label("\(automation.status.queuedRuns) queued", systemImage: "clock.arrow.circlepath")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(automation.execution.reason)
                .font(.callout)
                .foregroundStyle(.secondary)

            if let lastRunAt = automation.status.lastRunAt {
                HStack(spacing: 8) {
                    Image(systemName: automation.status.lastRunStatus == "succeeded" ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(automation.status.lastRunStatus == "succeeded" ? Color.green : Color.orange)
                    Text("Last run: \(lastRunAt)")
                    if let error = automation.status.lastError { Text("· \(error)") }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack {
                if automation.source.kind == "legacy_memory" {
                    Label("Imported from existing Geoffrey memory", systemImage: "arrow.down.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Tracked in private memory", systemImage: "arrow.triangle.branch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let resultPath = automation.status.lastResultPath {
                    Button("Open last result") { model.openAutomationResult(resultPath) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                if model.runningAutomationIDs.contains(automation.id) {
                    ProgressView().controlSize(.small)
                    Text("Running").font(.caption).foregroundStyle(.secondary)
                } else if automation.approval.state != "approved" || !automation.enabled {
                    Button("Review") { model.reviewAutomation(automation) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                } else if automation.execution.route == "cloud" && automation.execution.deploymentState != "active" {
                    Button("Connect cloud") { model.openCloudAutomationSetup(automation) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                } else if automation.execution.route == "local" && automation.status.failedRuns > 0 {
                    Button("Retry") { model.runAutomation(automation, retry: true) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!model.runningAutomationIDs.isEmpty)
                } else if automation.execution.canRun {
                    Button(automation.status.queuedRuns > 0 ? "Run queued" : "Run now") {
                        model.runAutomation(automation)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!model.runningAutomationIDs.isEmpty)
                } else {
                    Button("Review instructions") { model.reviewAutomation(automation) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct GeoffreyAutomationRunResponse: Codable {
    let ok: Bool
    let workflowID: String?
    let runID: String?
    let status: String?
    let resultPath: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, status, error
        case workflowID = "workflow_id"
        case runID = "run_id"
        case resultPath = "result_path"
    }
}
#endif
