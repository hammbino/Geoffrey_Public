struct GeoffreyConnectionRefreshResult<Value> {
    let value: Value
    let issue: String?
}

enum GeoffreyConnectionRefresh {
    static func resolve<Value>(
        latest: Value?,
        previous: Value,
        timedOut: Bool
    ) -> GeoffreyConnectionRefreshResult<Value> {
        if let latest {
            return GeoffreyConnectionRefreshResult(value: latest, issue: nil)
        }
        let issue = timedOut
            ? "The check took too long. Your saved connections are unchanged. Check the internet connection, then try again."
            : "Your saved connections are unchanged. Check the internet connection and try again; reconnect only if a specific account still needs attention."
        return GeoffreyConnectionRefreshResult(value: previous, issue: issue)
    }
}
