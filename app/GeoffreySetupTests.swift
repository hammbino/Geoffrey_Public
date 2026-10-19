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
        expect(needsBackup.nextStep?.id == .memory, "local memory does not require GitHub")

        let existingMemoryNeedsBackup = GeoffreySetupProgress.make(
            health: ["claude": "ready", "email": "1 connected", "github": "needs_setup", "memory": "/private/memory"],
            accountCount: 1,
            hasEngine: true
        )
        expect(existingMemoryNeedsBackup.isComplete, "local memory is usable without optional backup")

        let ready = GeoffreySetupProgress.make(
            health: ["claude": "ready", "email": "2 connected", "github": "ready", "memory": "/private/memory"],
            accountCount: 2,
            hasEngine: true
        )
        expect(ready.isComplete, "complete first-run state")
        expect(ready.completedCount == ready.steps.count, "all setup steps complete")

        let brokenRuntime = GeoffreySetupProgress.make(health: ["app": "needs_install"], accountCount: 0, hasEngine: true)
        expect(brokenRuntime.nextStep?.id == .engine, "an executable shell alone is not a working engine")
        for count in [1, 2, 10, 100] {
            let multiple = GeoffreySetupProgress.make(health: ["claude": "ready", "email": "\(count) connected", "memory": "/private/memory"], accountCount: count, hasEngine: true)
            expect(multiple.isComplete, "any positive number of healthy accounts supports setup")
        }
        print("Geoffrey setup tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
