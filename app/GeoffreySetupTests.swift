import Foundation

@main
struct GeoffreySetupTests {
    static func main() {
        let missingEngine = GeoffreySetupProgress.make(health: [:], accountCount: 0, hasEngine: false)
        expect(missingEngine.nextStep?.id == .engine, "engine repair is first")

        let firstUse = GeoffreySetupProgress.make(
            health: ["claude": "needs_login", "email": "needs_setup", "github": "needs_setup", "memory": "needs_setup"],
            accountCount: 0,
            hasEngine: true
        )
        expect(firstUse.completedCount == 1, "engine is retained on first use")
        expect(firstUse.nextStep?.id == .claude, "Claude sign-in is next")

        let needsAccount = GeoffreySetupProgress.make(
            health: ["claude": "ready", "email": "needs_setup", "github": "needs_setup", "memory": "needs_setup"],
            accountCount: 0,
            hasEngine: true
        )
        expect(needsAccount.nextStep?.id == .email, "email follows Claude")

        let needsBackup = GeoffreySetupProgress.make(
            health: ["claude": "ready", "email": "1 connected", "github": "needs_setup", "memory": "needs_setup"],
            accountCount: 1,
            hasEngine: true
        )
        expect(needsBackup.nextStep?.id == .github, "GitHub precedes new memory")

        let existingMemoryNeedsBackup = GeoffreySetupProgress.make(
            health: ["claude": "ready", "email": "1 connected", "github": "needs_setup", "memory": "/private/memory"],
            accountCount: 1,
            hasEngine: true
        )
        expect(existingMemoryNeedsBackup.nextStep?.id == .github, "existing memory does not hide a missing backup connection")

        let ready = GeoffreySetupProgress.make(
            health: ["claude": "ready", "email": "2 connected", "github": "ready", "memory": "/private/memory"],
            accountCount: 2,
            hasEngine: true
        )
        expect(ready.isComplete, "complete first-run state")
        expect(ready.completedCount == ready.steps.count, "all setup steps complete")

        print("Geoffrey setup tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
