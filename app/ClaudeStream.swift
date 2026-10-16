import Foundation

struct ClaudeStreamUpdate: Equatable, Sendable {
    var textDelta: String?
    var toolName: String?
    var finalText: String?
    var sessionID: String?
    var errorMessage: String?
    var isResult = false
}

struct ClaudeRunCompletion: Sendable {
    let status: Int32
    let streamedText: String
    let finalText: String?
    let sessionID: String?
    let errorMessage: String?
}

enum ClaudeStreamParser {
    static func parse(line: String) -> ClaudeStreamUpdate? {
        let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty,
              let data = clean.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let payload = object as? [String: Any],
              let type = payload["type"] as? String else {
            return nil
        }

        let sessionID = payload["session_id"] as? String
        switch type {
        case "system":
            return ClaudeStreamUpdate(sessionID: sessionID)

        case "stream_event":
            guard let event = payload["event"] as? [String: Any],
                  let eventType = event["type"] as? String else {
                return sessionID.map { ClaudeStreamUpdate(sessionID: $0) }
            }
            if eventType == "content_block_delta",
               let delta = event["delta"] as? [String: Any],
               delta["type"] as? String == "text_delta",
               let text = delta["text"] as? String {
                return ClaudeStreamUpdate(textDelta: text, sessionID: sessionID)
            }
            if eventType == "content_block_start",
               let block = event["content_block"] as? [String: Any],
               block["type"] as? String == "tool_use",
               let name = block["name"] as? String {
                return ClaudeStreamUpdate(toolName: name, sessionID: sessionID)
            }
            return sessionID.map { ClaudeStreamUpdate(sessionID: $0) }

        case "assistant":
            guard let message = payload["message"] as? [String: Any],
                  let content = message["content"] as? [[String: Any]],
                  let tool = content.first(where: { $0["type"] as? String == "tool_use" }),
                  let name = tool["name"] as? String else {
                return sessionID.map { ClaudeStreamUpdate(sessionID: $0) }
            }
            return ClaudeStreamUpdate(toolName: name, sessionID: sessionID)

        case "result":
            let isError = payload["is_error"] as? Bool == true
            let result = payload["result"] as? String
            return ClaudeStreamUpdate(
                finalText: isError ? nil : result,
                sessionID: sessionID,
                errorMessage: isError ? (result ?? "Claude could not complete the request.") : nil,
                isResult: true
            )

        default:
            return sessionID.map { ClaudeStreamUpdate(sessionID: $0) }
        }
    }
}
