import Foundation

@main
struct ClaudeStreamTests {
    static func main() {
        expect(
            ClaudeStreamParser.parse(line: #"{"type":"system","subtype":"init","session_id":"session-1"}"#)?.sessionID == "session-1",
            "captures the session identifier"
        )
        expect(
            ClaudeStreamParser.parse(line: #"{"type":"stream_event","event":{"type":"content_block_delta","delta":{"type":"text_delta","text":"Hello "}}}"#)?.textDelta == "Hello ",
            "captures partial text"
        )
        expect(
            ClaudeStreamParser.parse(line: #"{"type":"stream_event","event":{"type":"content_block_start","content_block":{"type":"tool_use","name":"Read"}}}"#)?.toolName == "Read",
            "captures tool activity"
        )
        let success = ClaudeStreamParser.parse(line: #"{"type":"result","subtype":"success","is_error":false,"result":"Hello world","session_id":"session-1"}"#)
        expect(success?.isResult == true && success?.finalText == "Hello world" && success?.sessionID == "session-1", "captures the final result")

        let failure = ClaudeStreamParser.parse(line: #"{"type":"result","subtype":"error","is_error":true,"result":"Not logged in","session_id":"session-2"}"#)
        expect(failure?.isResult == true && failure?.errorMessage == "Not logged in" && failure?.finalText == nil, "captures a structured failure")
        expect(ClaudeStreamParser.parse(line: "not json") == nil, "ignores non-JSON diagnostic lines")

        print("Claude stream parser tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
