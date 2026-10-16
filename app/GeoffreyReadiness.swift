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
