import Foundation

enum GeoffreyReadinessState: String, Equatable, Sendable {
    case ready
    case needsAttention
}

struct GeoffreyReadinessItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let detail: String
    let state: GeoffreyReadinessState
    let actionTitle: String?
}

enum GeoffreyReadiness {
    static func items(
        health: [String: String],
        accountCount: Int,
        accountsNeedingRepair: Int,
        capabilityCount: Int,
        capabilitiesNeedingRepair: Int
    ) -> [GeoffreyReadinessItem] {
        let claudeReady = health["claude"] == "ready"
        let githubReady = health["github"] == "ready"
        let memoryReady = (health["memory"] ?? "").hasPrefix("/")
        let emailReady = accountCount > 0 && accountsNeedingRepair == 0
        let capabilitiesReady = capabilityCount > 0 && capabilitiesNeedingRepair == 0

        return [
            GeoffreyReadinessItem(
                id: "claude",
                title: "Claude",
                detail: claudeReady
                    ? "Signed in and ready to reason, use skills, and work with approved tools."
                    : (health["claude"] == "needs_setup"
                        ? "Claude Code needs to be installed before Geoffrey can help."
                        : "Sign in once so Geoffrey can use your Claude account."),
                state: claudeReady ? .ready : .needsAttention,
                actionTitle: claudeReady ? nil : "Sign in"
            ),
            GeoffreyReadinessItem(
                id: "email",
                title: "Email and calendars",
                detail: emailReady
                    ? "\(accountCount) account\(accountCount == 1 ? "" : "s") connected and healthy."
                    : (accountCount == 0
                        ? "Connect at least one account for briefings and follow-ups."
                        : "\(accountsNeedingRepair) account\(accountsNeedingRepair == 1 ? "" : "s") need\(accountsNeedingRepair == 1 ? "s" : "") attention."),
                state: emailReady ? .ready : .needsAttention,
                actionTitle: accountCount == 0 ? "Add account" : (emailReady ? nil : "Review")
            ),
            GeoffreyReadinessItem(
                id: "memory",
                title: "Private memory",
                detail: memoryReady
                    ? "Geoffrey can retain approved preferences, projects, and feedback."
                    : "Create private memory so Geoffrey improves instead of starting over.",
                state: memoryReady ? .ready : .needsAttention,
                actionTitle: memoryReady ? nil : "Set up"
            ),
            GeoffreyReadinessItem(
                id: "github",
                title: "GitHub backup",
                detail: githubReady
                    ? "Portable, non-secret Geoffrey state can sync to the owner's GitHub account."
                    : "Connect GitHub so memory and approved workflows remain portable.",
                state: githubReady ? .ready : .needsAttention,
                actionTitle: githubReady ? nil : "Connect"
            ),
            GeoffreyReadinessItem(
                id: "capabilities",
                title: "Claude capabilities",
                detail: capabilitiesReady
                    ? "\(capabilityCount) skill\(capabilityCount == 1 ? "" : "s"), plugin\(capabilityCount == 1 ? "" : "s"), and connection\(capabilityCount == 1 ? "" : "s") available."
                    : (capabilityCount == 0
                        ? "Geoffrey could not inventory Claude's skills, plugins, and connections yet."
                        : "\(capabilitiesNeedingRepair) Claude capabilit\(capabilitiesNeedingRepair == 1 ? "y needs" : "ies need") attention."),
                state: capabilitiesReady ? .ready : .needsAttention,
                actionTitle: capabilitiesReady ? nil : "Review"
            ),
        ]
    }
}

struct GeoffreyCapability: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let source: String
    let enabled: Bool
    let state: String?
    let repair: String?
    let description: String

    var displayName: String { name.replacingOccurrences(of: "-", with: " ").capitalized }
    var isReady: Bool { (state ?? (enabled ? "ready" : "needs_attention")) == "ready" }
    var statusLabel: String {
        switch state {
        case "disabled": return "Disabled"
        case "needs_login": return "Sign in needed"
        case "pending": return "Approval needed"
        case "needs_attention": return "Needs attention"
        default: return isReady ? "Ready" : "Needs attention"
        }
    }
    var repairTitle: String? {
        guard !isReady else { return nil }
        switch repair {
        case "enable_plugin": return "Enable"
        case "login_mcp": return "Reconnect"
        default: return "How to fix"
        }
    }
    var commandIdentifier: String {
        guard let separator = id.firstIndex(of: ":") else { return name }
        return String(id[id.index(after: separator)...])
    }
    var kindLabel: String {
        switch type {
        case "mcp": return "Connection"
        case "plugin": return "Claude plugin"
        default: return "Skill"
        }
    }
    var icon: String {
        switch type {
        case "mcp": return "link.circle.fill"
        case "plugin": return "puzzlepiece.extension.fill"
        default: return "wand.and.stars"
        }
    }
}

enum GeoffreyReadinessRefresh {
    static func health(output: String, status: Int32) -> [String: String]? {
        guard status == 0 else { return nil }
        var entries: [String: String] = [:]
        for line in output.split(separator: "\n") {
            let pair = line.split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            guard pair.count == 2, !pair[1].isEmpty, entries[pair[0]] == nil else { return nil }
            entries[pair[0]] = pair[1]
        }
        guard ["claude", "email", "github", "memory", "app"].allSatisfy({ entries[$0] != nil }) else { return nil }
        return entries
    }

    static func capabilities(output: String, status: Int32) -> [GeoffreyCapability]? {
        guard status == 0 else { return nil }
        return try? JSONDecoder().decode([GeoffreyCapability].self, from: Data(output.utf8))
    }

    static func issue(status: Int32, subject: String) -> String {
        let reason = status == 124 ? "The check took too long." : "Geoffrey could not check \(subject)."
        return "\(reason) Saved setup has not been reset. Any results below are from the last successful check. Try refreshing again."
    }
}
