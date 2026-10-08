import AppKit
import Foundation
import SwiftUI

@main
struct GeoffreyApp: App {
    @StateObject private var model = GeoffreyModel()

    var body: some Scene {
        WindowGroup {
            GeoffreyRootView()
                .environmentObject(model)
                .frame(minWidth: 920, minHeight: 650)
                .task { model.refresh() }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh Geoffrey") { model.refresh() }
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
}

enum GeoffreySection: Hashable {
    case today, ask, improve, connections, memory, settings
}

struct GeoffreyRootView: View {
    @EnvironmentObject private var model: GeoffreyModel
    @State private var selection: GeoffreySection? = .today

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    Label("Today", systemImage: "sun.max.fill").tag(GeoffreySection.today)
                    Label("Ask Geoffrey", systemImage: "message.fill").tag(GeoffreySection.ask)
                }
                Section("Your business") {
                    Label("Improve Geoffrey", systemImage: "wand.and.stars").tag(GeoffreySection.improve)
                    Label("Connections", systemImage: "link").tag(GeoffreySection.connections)
                    Label("Memory", systemImage: "brain.head.profile").tag(GeoffreySection.memory)
                }
                Section {
                    Label("Settings", systemImage: "gearshape").tag(GeoffreySection.settings)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Geoffrey")
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    Circle().fill(model.isReady ? Color.green : Color.orange).frame(width: 8, height: 8)
                    Text(model.isReady ? "Ready to help" : "Finishing setup")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
            }
        } detail: {
            switch selection ?? .today {
            case .today: TodayView()
            case .ask: AskGeoffreyView()
            case .improve: ImproveGeoffreyView()
            case .connections: ConnectionsView()
            case .memory: MemoryView()
            case .settings: SettingsView()
            }
        }
        .tint(Color(red: 0.08, green: 0.45, blue: 0.36))
        .alert("Geoffrey needs a little attention", isPresented: $model.showingIssue) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(model.issueMessage)
        }
    }
}

struct TodayView: View {
    @EnvironmentObject private var model: GeoffreyModel
    @State private var feedbackSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.greeting)
                            .font(.system(size: 30, weight: .semibold))
                        Text("A clear view of the day, then one useful next move.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        model.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh Geoffrey")
                }

                if !model.isReady {
                    SetupBanner()
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Your daily briefing", systemImage: "sun.max.fill")
                            .font(.headline)
                        Spacer()
                        if model.isRunning { ProgressView().controlSize(.small) }
                    }
                    Text("Meetings, priorities, follow-ups, and the things most likely to slip.")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ActionButton(title: "Brief me", icon: "sparkles", prominent: true) { model.run(task: .daily) }
                        ActionButton(title: "Inbox", icon: "tray.full") { model.run(task: .inbox) }
                        ActionButton(title: "Follow-ups", icon: "arrowshape.turn.up.right") { model.run(task: .followUp) }
                        ActionButton(title: "Open loops", icon: "checklist") { model.run(task: .openLoops) }
                    }
                    .disabled(model.isRunning || !model.canTalk)
                }
                .padding(22)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let response = model.latestResponse {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(response.title).font(.headline)
                            Spacer()
                            Text(response.date, style: .time).font(.caption).foregroundStyle(.secondary)
                        }
                        Text(response.text)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                        HStack(spacing: 10) {
                            Text("Did this help?").foregroundStyle(.secondary)
                            Button {
                                model.sendFeedback(rating: "helpful", note: "The owner marked this briefing helpful.")
                            } label: {
                                Label("Helpful", systemImage: "hand.thumbsup")
                            }
                            .buttonStyle(.bordered)
                            Button {
                                feedbackSheet = true
                            } label: {
                                Label("Adjust it", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(22)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if !model.isRunning {
                    EmptyStateView()
                }
            }
            .padding(32)
            .frame(maxWidth: 980, alignment: .leading)
        }
        .sheet(isPresented: $feedbackSheet) { FeedbackSheet() }
    }
}

struct AskGeoffreyView: View {
    @EnvironmentObject private var model: GeoffreyModel
    @State private var request = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ask Geoffrey")
                .font(.system(size: 30, weight: .semibold))
            Text("Tell Geoffrey what you need. It can review, organize, plan, and prepare. It will always ask before anything is sent, posted, spent, or changed outside Geoffrey.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 720, alignment: .leading)

            TextEditor(text: $request)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(12)
                .frame(minHeight: 150)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Button("Ask Geoffrey") {
                    let question = request.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !question.isEmpty else { return }
                    model.run(task: .ask(question))
                    request = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(request.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isRunning || !model.canTalk)
                if model.isRunning { ProgressView("Geoffrey is working") }
            }

            if let response = model.latestResponse, case .ask = response.kind {
                Divider().padding(.vertical, 8)
                Text(response.text)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: 980, alignment: .leading)
    }
}

struct ImproveGeoffreyView: View {
    @EnvironmentObject private var model: GeoffreyModel
    @State private var showingSkillBuilder = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Improve Geoffrey")
                    .font(.system(size: 30, weight: .semibold))
                Text("Turn recurring work into a better Geoffrey. Start with a recommendation, then approve only the capability you want added.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 760, alignment: .leading)

                HStack(alignment: .top, spacing: 18) {
                    CapabilityPanel(
                        icon: "lightbulb.max.fill",
                        title: "Find the next best capability",
                        detail: "Geoffrey reviews your projects, open loops, tools, and briefing feedback, then recommends no more than three useful improvements.",
                        actionTitle: "Review my work"
                    ) {
                        model.run(task: .capabilityReview)
                    }
                    CapabilityPanel(
                        icon: "hammer.fill",
                        title: "Build a custom skill",
                        detail: "Teach Geoffrey one repeatable workflow for your business, such as proposal follow-ups, client prep, or content review.",
                        actionTitle: "Build a skill"
                    ) {
                        showingSkillBuilder = true
                    }
                }
                .disabled(model.isRunning || !model.canTalk)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Business tools and plugins", systemImage: "puzzlepiece.extension")
                        .font(.headline)
                    Text("When Geoffrey recommends an outside tool, it tells you the first win and the smallest access it needs. Geoffrey will never connect an account or install an outside integration without your approval.")
                        .foregroundStyle(.secondary)
                    Button("Plan a business-tool connection") { model.openSetup("connect-tool") }
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                }
                .padding(20)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let response = model.latestResponse, response.kind.isCapabilityOutput {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(response.title).font(.headline)
                        Text(response.text)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(22)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(32)
            .frame(maxWidth: 980, alignment: .leading)
        }
        .sheet(isPresented: $showingSkillBuilder) { SkillBuilderSheet() }
    }
}

struct CapabilityPanel: View {
    let icon: String
    let title: String
    let detail: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(Color(red: 0.08, green: 0.45, blue: 0.36))
            Text(title).font(.headline)
            Text(detail).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Button(actionTitle, action: action).buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SkillBuilderSheet: View {
    @EnvironmentObject private var model: GeoffreyModel
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Build a Geoffrey skill")
                .font(.title2.weight(.semibold))
            Text("Describe work you do repeatedly. Geoffrey will create a private skill for that workflow and will not connect accounts, send messages, or change other systems.")
                .foregroundStyle(.secondary)
            TextEditor(text: $description)
                .padding(8)
                .frame(height: 130)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create private skill") {
                    let request = description.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !request.isEmpty else { return }
                    model.run(task: .buildSkill(request))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 520)
    }
}

struct ConnectionsView: View {
    @EnvironmentObject private var model: GeoffreyModel

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Connections")
                .font(.system(size: 30, weight: .semibold))
            Text("Geoffrey only sees the accounts you choose to connect. Email and calendars are read-only unless you explicitly approve an action.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 700, alignment: .leading)

            ConnectionRow(icon: "envelope.fill", title: "Email and calendar", detail: model.health["email"] ?? "Checking...", ready: model.health["email"]?.contains("connected") == true) {
                model.openSetup("add-email")
            }
            ConnectionRow(icon: "sparkles", title: "Claude", detail: model.health["claude"] == "ready" ? "Ready" : "Sign in needed", ready: model.health["claude"] == "ready") {
                model.openClaudeLogin()
            }
            ConnectionRow(icon: "brain.head.profile", title: "Private memory", detail: model.memoryDetail, ready: model.hasMemory) {
                model.openSetup("setup")
            }
            ConnectionRow(icon: "arrow.triangle.branch", title: "Private GitHub backup", detail: model.health["github"] == "ready" ? "Connected" : "Not connected yet", ready: model.health["github"] == "ready") {
                model.openSetup("setup")
            }
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: 900, alignment: .leading)
    }
}

struct MemoryView: View {
    @EnvironmentObject private var model: GeoffreyModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Geoffrey remembers")
                .font(.system(size: 30, weight: .semibold))
            Text("Your private Geoffrey memory holds agreed preferences, projects, people, decisions, and the feedback that makes future briefings more useful. It is backed up to your private GitHub repository, not shared with other Geoffrey users.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 760, alignment: .leading)

            if model.hasMemory {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Memory home", systemImage: "lock.fill")
                        .font(.headline)
                    Text(model.memoryDetail).font(.callout).foregroundStyle(.secondary)
                    Button("Open memory folder") { model.openMemory() }
                        .buttonStyle(.bordered)
                }
                .padding(20)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                SetupBanner()
            }
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: 980, alignment: .leading)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model: GeoffreyModel

    var body: some View {
        Form {
            Section("Geoffrey") {
                LabeledContent("Geoffrey folder", value: model.geoffreyHome)
                Button("Check for updates") { model.runMaintenance("update-check") }
                Button("Open Geoffrey folder") { model.openGeoffreyFolder() }
            }
            Section("Help") {
                Text("Geoffrey asks before sending, publishing, spending, deleting, or changing access. Feedback on a briefing is saved privately so Geoffrey can make the next one better.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(32)
        .navigationTitle("Settings")
    }
}

struct SetupBanner: View {
    @EnvironmentObject private var model: GeoffreyModel

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "wand.and.stars").font(.title2).foregroundStyle(Color.orange)
            VStack(alignment: .leading, spacing: 5) {
                Text("Let’s finish your setup") .font(.headline)
                Text("Connect your email and create your private memory so Geoffrey can work with your real business context.")
                    .foregroundStyle(.secondary)
                Button("Continue setup") { model.openSetup("setup") }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding(18)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start with a briefing") .font(.headline)
            Text("Geoffrey will bring together your day, your connected email and calendar, and the work that needs attention.")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 22)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        if prominent {
            Button(action: action) { Label(title, systemImage: icon) }
                .buttonStyle(.borderedProminent)
        } else {
            Button(action: action) { Label(title, systemImage: icon) }
                .buttonStyle(.bordered)
        }
    }
}

struct ConnectionRow: View {
    let icon: String
    let title: String
    let detail: String
    let ready: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).frame(width: 24).font(.title3).foregroundStyle(ready ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(detail).foregroundStyle(.secondary)
            }
            Spacer()
            if !ready { Button("Set up", action: action).buttonStyle(.bordered) }
            else { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
        }
        .padding(.vertical, 12)
        Divider()
    }
}

struct FeedbackSheet: View {
    @EnvironmentObject private var model: GeoffreyModel
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @State private var selected = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Help Geoffrey improve") .font(.title2.weight(.semibold))
            Text("What would make the next morning briefing more useful?") .foregroundStyle(.secondary)
            Picker("", selection: $selected) {
                Text("Choose one").tag("")
                Text("Shorter and more focused").tag("Make future briefings shorter and more focused.")
                Text("Less email detail").tag("Reduce routine email detail unless it needs attention.")
                Text("More calendar and priorities").tag("Put more emphasis on calendar risks and priorities.")
                Text("More follow-ups").tag("Surface more client, prospect, and waiting follow-ups.")
                Text("Something else").tag("custom")
            }
            .pickerStyle(.menu)
            TextEditor(text: $note)
                .padding(8)
                .frame(height: 90)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save feedback") {
                    let extra = note.trimmingCharacters(in: .whitespacesAndNewlines)
                    let selectedText = selected == "custom" ? "" : selected
                    let message = [selectedText, extra].filter { !$0.isEmpty }.joined(separator: " ")
                    model.sendFeedback(rating: "adjust", note: message.isEmpty ? "The owner asked to adjust this briefing." : message)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}

enum GeoffreyTask: Equatable {
    case daily, inbox, followUp, openLoops, ask(String), capabilityReview, buildSkill(String)

    var commandName: String {
        switch self {
        case .daily: return "daily"
        case .inbox: return "inbox"
        case .followUp: return "follow-up"
        case .openLoops: return "open-loops"
        case .ask: return "ask"
        case .capabilityReview: return "capability-review"
        case .buildSkill: return "build-skill"
        }
    }

    var title: String {
        switch self {
        case .daily: return "Your daily briefing"
        case .inbox: return "Inbox rescue"
        case .followUp: return "Follow-ups"
        case .openLoops: return "Open loops"
        case .ask: return "Geoffrey’s response"
        case .capabilityReview: return "Ways to improve Geoffrey"
        case .buildSkill: return "Your new Geoffrey skill"
        }
    }

    var isCapabilityOutput: Bool {
        switch self {
        case .capabilityReview, .buildSkill: return true
        default: return false
        }
    }

    var allowsEdits: Bool {
        if case .buildSkill = self { return true }
        return false
    }
}

struct GeoffreyResponse {
    let title: String
    let text: String
    let date: Date
    let kind: GeoffreyTask
}

@MainActor
final class GeoffreyModel: ObservableObject {
    @Published var health: [String: String] = [:]
    @Published var latestResponse: GeoffreyResponse?
    @Published var isRunning = false
    @Published var issueMessage = ""
    @Published var showingIssue = false

    let geoffreyHome: String

    init() {
        geoffreyHome = UserDefaults.standard.string(forKey: "geoffreyHome")
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Geoffrey").path
    }

    var hasMemory: Bool { (health["memory"] ?? "").hasPrefix("/") }
    var canTalk: Bool { health["claude"] == "ready" && hasMemory }
    var isReady: Bool { canTalk && (health["email"] ?? "").contains("connected") }
    var memoryDetail: String { hasMemory ? health["memory"]! : "Not created yet" }
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    func refresh() {
        Task.detached { [geoffreyHome] in
            let result = Self.run(executable: geoffreyHome + "/bin/geoffrey", arguments: ["app-status"])
            let entries = result.output.split(separator: "\n").reduce(into: [String: String]()) { values, line in
                let pair = line.split(separator: "\t", maxSplits: 1).map(String.init)
                if pair.count == 2 { values[pair[0]] = pair[1] }
            }
            await MainActor.run { self.health = entries }
        }
    }

    func run(task: GeoffreyTask) {
        guard !isRunning else { return }
        guard canTalk else {
            issueMessage = "Finish setup first so Geoffrey can use your private memory and connected tools."
            showingIssue = true
            return
        }
        isRunning = true
        Task.detached { [geoffreyHome] in
            var promptArgs = ["app-prompt", "--task", task.commandName]
            switch task {
            case let .ask(question), let .buildSkill(question):
                promptArgs += ["--request", question]
            default:
                break
            }
            let prompt = Self.run(executable: geoffreyHome + "/bin/geoffrey", arguments: promptArgs)
            guard prompt.status == 0 else {
                await MainActor.run { self.finishWithIssue(prompt.output) }
                return
            }
            let memory = Self.run(executable: geoffreyHome + "/bin/geoffrey", arguments: ["app-status"]).output
                .split(separator: "\n").first(where: { $0.hasPrefix("memory\t/") })?
                .split(separator: "\t", maxSplits: 1).last.map(String.init) ?? ""
            let answer = Self.runClaude(
                prompt: prompt.output,
                workingDirectory: memory,
                geoffreyHome: geoffreyHome,
                allowsEdits: task.allowsEdits
            )
            if answer.status == 0 && task.allowsEdits {
                _ = Self.run(executable: geoffreyHome + "/bin/geoffrey", arguments: ["app-sync"])
            }
            await MainActor.run {
                self.isRunning = false
                if answer.status == 0, !answer.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.latestResponse = GeoffreyResponse(title: task.title, text: answer.output.trimmingCharacters(in: .whitespacesAndNewlines), date: Date(), kind: task)
                } else {
                    self.finishWithIssue(answer.output.isEmpty ? "Geoffrey could not complete that request. Please try again." : answer.output)
                }
            }
        }
    }

    func sendFeedback(rating: String, note: String) {
        Task.detached { [geoffreyHome] in
            _ = Self.run(executable: geoffreyHome + "/bin/geoffrey", arguments: ["app-feedback", "--rating", rating, "--note", note])
        }
    }

    func openSetup(_ command: String) {
        openTerminal(command: "cd \(Self.shellQuote(geoffreyHome)) && ./bin/geoffrey \(command)")
    }

    func runMaintenance(_ command: String) { openTerminal(command: "cd \(Self.shellQuote(geoffreyHome)) && ./bin/geoffrey \(command)") }
    func openClaudeLogin() { openTerminal(command: "cd \(Self.shellQuote(geoffreyHome)) && claude") }
    func openMemory() { if hasMemory { NSWorkspace.shared.open(URL(fileURLWithPath: memoryDetail)) } }
    func openGeoffreyFolder() { NSWorkspace.shared.open(URL(fileURLWithPath: geoffreyHome)) }

    private func finishWithIssue(_ raw: String) {
        isRunning = false
        let message = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if message.localizedCaseInsensitiveContains("failed to authenticate") || message.localizedCaseInsensitiveContains("oauth session expired") {
            issueMessage = "Your Claude sign-in needs a quick refresh. Open Connections, choose Claude, and select Set up. Then come back here and try again."
        } else {
            issueMessage = message
        }
        showingIssue = true
    }

    private func openTerminal(command: String) {
        let script = "tell application \"Terminal\" to do script \"\(command.replacingOccurrences(of: "\\\"", with: "\\\\\\\""))\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    nonisolated private static func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\\"'\\\"'") + "'"
    }

    nonisolated private static func runClaude(prompt: String, workingDirectory: String, geoffreyHome: String, allowsEdits: Bool) -> CommandResult {
        var arguments = ["claude", "--print", "--output-format", "text", "--permission-mode", allowsEdits ? "acceptEdits" : "plan", "--name", "Geoffrey"]
        if !allowsEdits { arguments += ["--add-dir", geoffreyHome] }
        arguments.append(prompt)
        return run(executable: "/usr/bin/env", arguments: arguments, workingDirectory: workingDirectory)
    }

    nonisolated private static func run(executable: String, arguments: [String], workingDirectory: String? = nil) -> CommandResult {
        let process = Process()
        let output = Pipe()
        let error = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = workingDirectory.flatMap { URL(fileURLWithPath: $0) }
        process.standardOutput = output
        process.standardError = error
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = environment
        do {
            try process.run()
            process.waitUntilExit()
            let standard = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let errors = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return CommandResult(status: process.terminationStatus, output: standard.isEmpty ? errors : standard)
        } catch {
            return CommandResult(status: 1, output: error.localizedDescription)
        }
    }
}

struct CommandResult {
    let status: Int32
    let output: String
}
