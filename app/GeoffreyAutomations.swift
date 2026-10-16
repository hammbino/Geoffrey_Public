import Foundation
#if !AUTOMATION_LOGIC_ONLY
import AppKit
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
    let task: String?
    let enabled: Bool
    let cadence: GeoffreyAutomationCadence
    let execution: GeoffreyAutomationExecution
    let approval: GeoffreyAutomationApproval
    let source: GeoffreyAutomationSource
    let status: GeoffreyAutomationStatus
    let resultDestination: String

    enum CodingKeys: String, CodingKey {
        case id, name, purpose, task, enabled, cadence, execution, approval, source, status
        case resultDestination = "result_destination"
    }

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
    let times: [String]
}

struct GeoffreyAutomationExecution: Codable {
    let route: String
    let preference: String
    let reason: String
    let deploymentState: String
    let verifiedAt: String?
    let routineURL: String?
    let verificationMethod: String?
    let verificationRunURL: String?
    let missingCapabilities: [String]
    let canRun: Bool

    enum CodingKeys: String, CodingKey {
        case route, preference, reason
        case deploymentState = "deployment_state"
        case verifiedAt = "verified_at"
        case routineURL = "routine_url"
        case verificationMethod = "verification_method"
        case verificationRunURL = "verification_run_url"
        case missingCapabilities = "missing_capabilities"
        case canRun = "can_run"
    }
}

struct GeoffreyAutomationApproval: Codable {
    let state: String
    let approvedAt: String?

    enum CodingKeys: String, CodingKey {
        case state
        case approvedAt = "approved_at"
    }
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

struct GeoffreyAutomationSaveRequest: Codable {
    let id: String
    let name: String
    let purpose: String
    let task: String
    let route: String
    let timezone: String
    let times: [String]
    let resultDestination: String
    let approved: Bool
    let source: GeoffreyAutomationSource

    enum CodingKeys: String, CodingKey {
        case id, name, purpose, task, route, timezone, times, approved, source
        case resultDestination = "result_destination"
    }
}

struct GeoffreyAutomationSaveResponse: Codable {
    let ok: Bool
    let workflowID: String?
    let approvalState: String?
    let route: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, route, error
        case workflowID = "workflow_id"
        case approvalState = "approval_state"
    }
}

struct GeoffreyAutomationCloudLinkRequest: Codable {
    let workflowID: String
    let routineURL: String
    let connectorsReviewed: Bool
    let scheduleConfirmed: Bool
    let runURL: String
    let runReviewed: Bool

    enum CodingKeys: String, CodingKey {
        case workflowID = "workflow_id"
        case routineURL = "routine_url"
        case connectorsReviewed = "connectors_reviewed"
        case scheduleConfirmed = "schedule_confirmed"
        case runURL = "run_url"
        case runReviewed = "run_reviewed"
    }
}

struct GeoffreyAutomationCloudLinkResponse: Codable {
    let ok: Bool
    let workflowID: String?
    let deploymentState: String?
    let verifiedAt: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case ok, error
        case workflowID = "workflow_id"
        case deploymentState = "deployment_state"
        case verifiedAt = "verified_at"
    }
}

struct GeoffreyAutomationRoutePresentation {
    let title: String
    let icon: String
    let colorName: String

    init(route: String, deploymentState: String, approvalState: String) {
        switch route {
        case "cloud":
            if deploymentState == "active" && approvalState == "approved" {
                title = "Cloud run reviewed"
            } else if deploymentState == "connected" {
                title = "Cloud setup recorded"
            } else {
                title = "Cloud capable"
            }
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
                    Button { model.presentAutomationReview() } label: {
                        Label("Add automation", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
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
                Button("Edit") { model.presentAutomationReview(automation) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
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
                } else if automation.execution.route == "cloud" {
                    Button(automation.execution.deploymentState == "active" ? "Review cloud" : automation.execution.deploymentState == "connected" ? "Verify cloud" : "Connect cloud") {
                        model.openCloudAutomationSetup(automation)
                    }
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

struct CloudAutomationSetupSheet: View {
    @EnvironmentObject private var model: GeoffreyModel
    @Environment(\.dismiss) private var dismiss
    let automation: GeoffreyAutomation
    @State private var routineURL: String
    @State private var runURL: String
    @State private var connectorsReviewed: Bool
    @State private var scheduleConfirmed: Bool
    @State private var runReviewed: Bool
    @State private var copied = false

    init(automation: GeoffreyAutomation) {
        self.automation = automation
        let hasConnection = automation.execution.routineURL != nil
        _routineURL = State(initialValue: automation.execution.routineURL ?? "")
        _runURL = State(initialValue: automation.execution.verificationRunURL ?? "")
        _connectorsReviewed = State(initialValue: hasConnection)
        _scheduleConfirmed = State(initialValue: hasConnection)
        _runReviewed = State(initialValue: automation.execution.verificationMethod == "owner_reviewed_run")
    }

    private var canSave: Bool {
        let hasRoutine = !routineURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasRun = !runURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasRoutine && connectorsReviewed && scheduleConfirmed && (hasRun == runReviewed)
    }

    private var setupBrief: String {
        let task = automation.task ?? "Review this task in Geoffrey before cloud setup."
        return """
        Name: \(automation.name)
        Outcome: \(automation.purpose)
        Instructions: \(task)
        Schedule: \(automation.cadence.summary)
        Timezone: \(automation.cadence.timezone ?? TimeZone.current.identifier)
        Result: Return the private briefing in the Claude run session for owner review.
        Safety boundary: Do not send, post, publish, spend, delete, change access, or modify an outside system.
        """
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let outcome = model.cloudAutomationOutcome {
                    Image(systemName: model.cloudAutomationSucceeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(model.cloudAutomationSucceeded ? Color.green : Color.orange)
                    Text(model.cloudAutomationSucceeded ? "Cloud evidence saved" : "Cloud setup needs attention")
                        .font(.title2.weight(.semibold))
                    Text(outcome).foregroundStyle(.secondary)
                    HStack {
                        if !model.cloudAutomationSucceeded {
                            Button("Back") { model.cloudAutomationOutcome = nil }
                        }
                        Spacer()
                        Button("Done") { dismiss() }.buttonStyle(.borderedProminent)
                    }
                } else {
                    Text("Connect to Claude cloud")
                        .font(.title2.weight(.semibold))
                    Text("Claude Routines can run while this Mac is off. Routine creation remains in Claude so you can review its repositories, environment, usage, connectors, and schedule before it starts.")
                        .foregroundStyle(.secondary)
                    Text("Routines require a supported Claude plan and may be disabled by an organization owner.")
                        .font(.caption).foregroundStyle(.secondary)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.shield.fill").foregroundStyle(.orange)
                        Text("Routines run autonomously. Claude includes connected tools by default, and those tools may be able to write without another approval. Remove every connector this briefing does not need.")
                            .font(.callout)
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Prepare the routine").font(.headline)
                        Text(setupBrief)
                            .font(.callout)
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        HStack {
                            Button(copied ? "Copied" : "Copy setup brief") { copyBrief() }
                            Button(automation.execution.routineURL == nil ? "Open Claude Routines" : "Open saved routine") {
                                model.openClaudeRoutines(automation.execution.routineURL)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("2. Record what you approved").font(.headline)
                        TextField("https://claude.ai/code/routines/...", text: $routineURL)
                            .textFieldStyle(.roundedBorder)
                        Toggle("I confirmed Claude shows the approved times and timezone", isOn: $scheduleConfirmed)
                            .toggleStyle(.checkbox)
                        Toggle("I reviewed the included connectors and removed everything this routine does not need", isOn: $connectorsReviewed)
                            .toggleStyle(.checkbox)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. Verify a real result").font(.headline)
                        Text("In Claude, choose Run now. Open the completed session and confirm the result—not only the green status—then paste that session link here. You can save the connection first and return after the test run.")
                            .font(.callout).foregroundStyle(.secondary)
                        TextField("Optional: https://claude.ai/code/session_...", text: $runURL)
                            .textFieldStyle(.roundedBorder)
                        Toggle("I opened this run and confirmed it produced the expected result", isOn: $runReviewed)
                            .toggleStyle(.checkbox)
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Geoffrey stores only these non-secret Claude links and your review timestamps in private memory. It never stores a Routine API token in GitHub.")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Pilot boundary: the cloud result remains in its Claude session. Automatic import of that result into Geoffrey private memory is not connected yet.")
                        .font(.caption.weight(.medium)).foregroundStyle(.orange)

                    HStack {
                        Button("Cancel") { dismiss() }
                        Spacer()
                        if model.isSavingCloudAutomation { ProgressView().controlSize(.small) }
                        Button(runReviewed ? "Save verified run" : "Save connection") { save() }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canSave || model.isSavingCloudAutomation)
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 660, height: 760)
    }

    private func copyBrief() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(setupBrief, forType: .string)
        copied = true
    }

    private func save() {
        model.saveCloudAutomationLink(GeoffreyAutomationCloudLinkRequest(
            workflowID: automation.id,
            routineURL: routineURL.trimmingCharacters(in: .whitespacesAndNewlines),
            connectorsReviewed: connectorsReviewed,
            scheduleConfirmed: scheduleConfirmed,
            runURL: runURL.trimmingCharacters(in: .whitespacesAndNewlines),
            runReviewed: runReviewed
        ))
    }
}

struct AutomationReviewSheet: View {
    @EnvironmentObject private var model: GeoffreyModel
    @Environment(\.dismiss) private var dismiss
    @State private var workflowID: String
    @State private var name: String
    @State private var purpose: String
    @State private var task: String
    @State private var route: String
    @State private var runCount: Int
    @State private var runTimes: [Date]
    @State private var approved: Bool
    private let source: GeoffreyAutomationSource
    private let timezone: String

    init(automation: GeoffreyAutomation?) {
        let calendar = Calendar.current
        let defaults = [8, 13, 17].map { hour in
            calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        }
        let parsedTimes = (automation?.cadence.times ?? []).compactMap(Self.date(from:))
        let initialTimes = parsedTimes.isEmpty ? defaults : parsedTimes + Array(defaults.dropFirst(parsedTimes.count))
        _workflowID = State(initialValue: automation?.id ?? "workflow-\(UUID().uuidString.lowercased())")
        _name = State(initialValue: automation?.name ?? "")
        _purpose = State(initialValue: automation?.purpose ?? "")
        _task = State(initialValue: automation?.task ?? "")
        _route = State(initialValue: automation?.execution.preference == "local" ? "local" : "cloud")
        _runCount = State(initialValue: max(1, min(3, parsedTimes.isEmpty ? 3 : parsedTimes.count)))
        _runTimes = State(initialValue: Array(initialTimes.prefix(3)))
        _approved = State(initialValue: automation?.approval.state == "approved")
        source = automation?.source ?? GeoffreyAutomationSource(kind: "user_created", path: nil)
        timezone = automation?.cadence.timezone ?? TimeZone.current.identifier
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !purpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let outcome = model.automationSaveOutcome {
                    Image(systemName: model.automationSaveSucceeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(model.automationSaveSucceeded ? Color.green : Color.orange)
                    Text(model.automationSaveSucceeded ? "Automation saved" : "Automation needs attention")
                        .font(.title2.weight(.semibold))
                    Text(outcome).foregroundStyle(.secondary)
                    HStack {
                        if !model.automationSaveSucceeded {
                            Button("Back") { model.automationSaveOutcome = nil }
                        }
                        Spacer()
                        Button("Done") { dismiss() }.buttonStyle(.borderedProminent)
                    }
                } else {
                    Text(name.isEmpty ? "Add an automation" : "Review automation")
                        .font(.title2.weight(.semibold))
                    Text("Define the recurring result in plain language. Geoffrey saves the approved definition to private memory and will not silently create a cloud schedule.")
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 7) {
                        Text("Name").font(.headline)
                        TextField("For example: Social media briefing", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 7) {
                        Text("What is this for?").font(.headline)
                        TextField("For example: Surface social activity that needs attention", text: $purpose)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading, spacing: 7) {
                        Text("What should Geoffrey do?").font(.headline)
                        TextEditor(text: $task)
                            .padding(8)
                            .frame(height: 120)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("Do not include passwords, tokens, or API keys. Recurring work stays read-only.")
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Where should it run?").font(.headline)
                        Picker("Execution", selection: $route) {
                            Text("Claude cloud — works while this Mac is off").tag("cloud")
                            Text("This Mac — runs when Geoffrey is available").tag("local")
                        }
                        .pickerStyle(.radioGroup)
                        if route == "cloud" {
                            Text("Saving this definition does not create a Claude Routine. Geoffrey will ask before connecting a real cloud schedule.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Daily schedule").font(.headline)
                            Spacer()
                            Picker("Runs", selection: $runCount) {
                                Text("Once daily").tag(1)
                                Text("Twice daily").tag(2)
                                Text("Three times daily").tag(3)
                            }
                            .pickerStyle(.menu)
                        }
                        ForEach(0..<runCount, id: \.self) { index in
                            DatePicker("Run \(index + 1)", selection: $runTimes[index], displayedComponents: .hourAndMinute)
                        }
                        Text("Timezone: \(timezone)").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield.fill").foregroundStyle(Color(red: 0.08, green: 0.45, blue: 0.36))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Results stay in private Geoffrey memory").font(.headline)
                            Text("Run history and owner-ready results can sync to the owner’s private GitHub repository. Credentials never belong there.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    Toggle("I approve this recurring workflow and proposed schedule", isOn: $approved)
                        .toggleStyle(.checkbox)

                    HStack {
                        Button("Cancel") { dismiss() }
                        Spacer()
                        if model.isSavingAutomation { ProgressView().controlSize(.small) }
                        Button(approved ? "Save approved workflow" : "Save draft") { save() }
                            .buttonStyle(.borderedProminent)
                            .disabled(!canSave || model.isSavingAutomation)
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 620, height: 720)
    }

    private func save() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: timezone)
        let request = GeoffreyAutomationSaveRequest(
            id: workflowID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            purpose: purpose.trimmingCharacters(in: .whitespacesAndNewlines),
            task: task.trimmingCharacters(in: .whitespacesAndNewlines),
            route: route,
            timezone: timezone,
            times: runTimes.prefix(runCount).map { formatter.string(from: $0) },
            resultDestination: "private_memory",
            approved: approved,
            source: source
        )
        model.saveAutomation(request)
    }

    private static func date(from value: String) -> Date? {
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return Calendar.current.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: Date())
    }
}
#endif
