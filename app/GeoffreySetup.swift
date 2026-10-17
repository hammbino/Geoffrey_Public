import Foundation

enum GeoffreySetupStepID: String, CaseIterable, Equatable, Sendable {
    case engine
    case claude
    case email
    case github
    case memory
}

struct GeoffreySetupStep: Identifiable, Equatable, Sendable {
    let id: GeoffreySetupStepID
    let title: String
    let detail: String
    let actionTitle: String
    let isComplete: Bool
}

struct GeoffreySetupProgress: Equatable, Sendable {
    let steps: [GeoffreySetupStep]

    var completedCount: Int { steps.filter(\.isComplete).count }
    var isComplete: Bool { nextStep == nil }
    var nextStep: GeoffreySetupStep? { steps.first(where: { !$0.isComplete }) }

    static func make(
        health: [String: String],
        accountCount: Int,
        hasEngine: Bool
    ) -> GeoffreySetupProgress {
        let engineReady = hasEngine
        let claudeReady = health["claude"] == "ready"
        let emailReady = accountCount > 0 && (health["email"] ?? "").contains("connected")
        let githubReady = health["github"] == "ready"
        let memoryReady = (health["memory"] ?? "").hasPrefix("/")

        return GeoffreySetupProgress(steps: [
            GeoffreySetupStep(
                id: .engine,
                title: "Geoffrey app",
                detail: engineReady
                    ? "The private Geoffrey helper is installed."
                    : "Geoffrey needs to repair its private helper before setup can continue.",
                actionTitle: "Repair Geoffrey",
                isComplete: engineReady
            ),
            GeoffreySetupStep(
                id: .claude,
                title: "Claude",
                detail: claudeReady
                    ? "Signed in and ready to help."
                    : (health["claude"] == "needs_setup"
                        ? "Install the Geoffrey release that includes its required Claude helper."
                        : "Sign in once with the Claude account Geoffrey should use."),
                actionTitle: health["claude"] == "needs_setup" ? "Repair Geoffrey" : "Sign in to Claude",
                isComplete: claudeReady
            ),
            GeoffreySetupStep(
                id: .email,
                title: "Email and calendar",
                detail: emailReady
                    ? "At least one account is connected."
                    : "Connect one inbox so Geoffrey can prepare useful briefings.",
                actionTitle: "Connect an account",
                isComplete: emailReady
            ),
            GeoffreySetupStep(
                id: .github,
                title: "Private backup",
                detail: githubReady
                    ? "GitHub is connected for portable, non-secret memory."
                    : "Connect GitHub so your approved memory is recoverable on another Mac.",
                actionTitle: "Connect GitHub",
                isComplete: githubReady
            ),
            GeoffreySetupStep(
                id: .memory,
                title: "Private memory",
                detail: memoryReady
                    ? "Your preferences, projects, and feedback have a private home."
                    : "Create or restore the private memory that helps Geoffrey improve over time.",
                actionTitle: "Set up private memory",
                isComplete: memoryReady
            ),
        ])
    }
}
