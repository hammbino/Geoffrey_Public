import Foundation

@main
struct GeoffreyMemoryTests {
    static func main() throws {
        let good = String(decoding: try JSONEncoder().encode(GeoffreyMemorySyncStatus.notChecked), as: UTF8.self)
        let decoded = GeoffreyMemoryStatusRefresh.decode(GeoffreyMemorySyncStatus.self, output: good, status: 0)
        expect(decoded?.state == "not_checked", "successful status decodes")
        for (output, status) in [("invalid", Int32(0)), (good, Int32(1)), (good, Int32(124))] {
            expect(GeoffreyMemoryStatusRefresh.decode(GeoffreyMemorySyncStatus.self, output: output, status: status) == nil, "failed read must not replace prior status")
        }
        expect(GeoffreyMemoryStatusRefresh.decode(GeoffreyMemorySyncStatus.self, output: good, status: 1, acceptsFailureReport: true) != nil, "sync may return structured conflict or credential failure with nonzero exit")
        expect(GeoffreyMemoryStatusRefresh.decode(GeoffreyMemorySyncStatus.self, output: good, status: 124, acceptsFailureReport: true) == nil, "timeout output must not be trusted as completed sync")
        let portable = String(decoding: try JSONEncoder().encode(GeoffreyPortableStateStatus.notChecked), as: UTF8.self)
        expect(GeoffreyMemoryStatusRefresh.decode(GeoffreyPortableStateStatus.self, output: portable, status: 0)?.state == "not_checked", "recovery-map read decodes")
        expect(GeoffreyMemoryStatusRefresh.decode(GeoffreyPortableStateStatus.self, output: good, status: 0) == nil, "wrong status shape cannot replace recovery map")
        expect(GeoffreyPortableStateStatus.notChecked.title == "Recovery map not checked", "unchecked map must not claim it needs an update")
        expect(GeoffreyMemoryStatusRefresh.issue(status: 124, subject: "backup").contains("too long"), "timeout has recovery guidance")
        expect(GeoffreyMemoryStatusRefresh.issue(status: 1, subject: "backup").contains("last successful check"), "failure identifies stale state")
        print("Geoffrey memory status tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
