import Foundation

struct GeoffreyMemorySyncStatus: Codable {
    let state: String
    let checkedAt: String?
    let branch: String?
    let head: String?
    let ahead: Int
    let behind: Int
    let dirty: Bool
    let message: String
    let recovery: String?

    enum CodingKeys: String, CodingKey {
        case state, branch, head, ahead, behind, dirty, message, recovery
        case checkedAt = "checked_at"
    }

    static let notChecked = GeoffreyMemorySyncStatus(
        state: "not_checked",
        checkedAt: nil,
        branch: nil,
        head: nil,
        ahead: 0,
        behind: 0,
        dirty: false,
        message: "Geoffrey has not checked the GitHub backup yet.",
        recovery: nil
    )

    var title: String {
        switch state {
        case "synced": return "Backed up"
        case "local_only": return "Saved on this Mac"
        case "local_changes": return "Changes waiting to back up"
        case "conflict": return "Two versions need review"
        case "blocked_secret": return "Credential kept off GitHub"
        case "needs_attention": return "Backup needs attention"
        case "not_configured": return "Backup not configured"
        default: return "Backup not checked"
        }
    }

    var icon: String {
        switch state {
        case "synced": return "checkmark.icloud.fill"
        case "conflict": return "arrow.triangle.branch"
        case "needs_attention": return "exclamationmark.icloud.fill"
        case "blocked_secret": return "lock.shield.fill"
        case "local_only": return "externaldrive.fill"
        case "local_changes": return "arrow.up.circle.fill"
        default: return "icloud.slash"
        }
    }

    var isHealthy: Bool { state == "synced" }
}

struct GeoffreyPortableStateStatus: Codable {
    let state: String
    let updatedAt: String?
    let manifestPath: String?
    let skillsCount: Int
    let connectorsCount: Int
    let reconnectCount: Int
    let message: String
    let recovery: String?

    enum CodingKeys: String, CodingKey {
        case state, message, recovery
        case updatedAt = "updated_at"
        case manifestPath = "manifest_path"
        case skillsCount = "skills_count"
        case connectorsCount = "connectors_count"
        case reconnectCount = "reconnect_count"
    }

    static let notChecked = GeoffreyPortableStateStatus(
        state: "not_checked",
        updatedAt: nil,
        manifestPath: nil,
        skillsCount: 0,
        connectorsCount: 0,
        reconnectCount: 0,
        message: "Geoffrey has not checked recovery information yet.",
        recovery: nil
    )

    var title: String {
        switch state {
        case "ready": return "Recovery map ready"
        case "not_checked": return "Recovery map not checked"
        default: return "Recovery map needs updating"
        }
    }
    var icon: String { state == "ready" ? "checkmark.shield.fill" : "arrow.triangle.2.circlepath" }
}

enum GeoffreyMemoryStatusRefresh {
    static func decode<Value: Decodable>(_ type: Value.Type, output: String, status: Int32, acceptsFailureReport: Bool = false) -> Value? {
        guard status == 0 || (acceptsFailureReport && status != 124) else { return nil }
        return try? JSONDecoder().decode(type, from: Data(output.utf8))
    }

    static func issue(status: Int32, subject: String) -> String {
        let reason = status == 124 ? "The check took too long." : "Geoffrey could not read \(subject)."
        return "\(reason) Any status below is from the last successful check. Check again before relying on it."
    }
}
