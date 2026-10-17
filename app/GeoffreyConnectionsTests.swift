import Foundation

@main
struct GeoffreyConnectionsTests {
    static func main() {
        let refreshed = GeoffreyConnectionRefresh.resolve(
            latest: ["work", "personal"],
            previous: ["old"],
            timedOut: false
        )
        expect(refreshed.value == ["work", "personal"], "successful refresh replaces prior state")
        expect(refreshed.issue == nil, "successful refresh clears the recovery state")

        let failed: GeoffreyConnectionRefreshResult<[String]> = GeoffreyConnectionRefresh.resolve(
            latest: nil,
            previous: ["work"],
            timedOut: false
        )
        expect(failed.value == ["work"], "failed refresh preserves prior accounts")
        expect(failed.issue?.contains("unchanged") == true, "failed refresh explains preservation")
        expect(failed.issue?.contains("reconnect only if") == true, "failed refresh avoids unnecessary reconnects")

        let timedOut: GeoffreyConnectionRefreshResult<[String]> = GeoffreyConnectionRefresh.resolve(
            latest: nil,
            previous: ["work"],
            timedOut: true
        )
        expect(timedOut.value == ["work"], "timeout preserves prior accounts")
        expect(timedOut.issue?.contains("too long") == true, "timeout has specific recovery guidance")

        print("Geoffrey connection refresh tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
