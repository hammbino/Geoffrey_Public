import Foundation
import Security

// Narrow stdin-only adapter for the engine. The security CLI's interactive
// password input truncates long OAuth JSON; SecItem APIs accept the full Data.
@main
struct GeoffreyKeychain {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())
        if args.contains("--no-ui") { SecKeychainSetUserInteractionAllowed(false) }
        func option(_ name: String) -> String? {
            guard let index = args.firstIndex(of: name), index + 1 < args.count else { return nil }
            return args[index + 1]
        }
        guard let operation = args.first,
              let service = option("-s"), service == "com.geoffrey.desktop.oauth.v1",
              let account = option("-a"), !account.isEmpty else { exit(2) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        var status: OSStatus
        switch operation {
        case "add-generic-password":
            var data = Data()
            while true {
                let chunk = FileHandle.standardInput.readData(ofLength: 16_384)
                if chunk.isEmpty { break }
                data.append(chunk)
                if data.count > 1_048_576 { exit(2) }
            }
            guard !data.isEmpty else { exit(2) }
            var attributes: [String: Any] = [kSecValueData as String: data]
            if let label = option("-l") { attributes[kSecAttrLabel as String] = label }
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status == errSecItemNotFound {
                // Set access when creating, preserving existing ACLs on update.
                var trusted: [SecTrustedApplication] = []
                for path in [CommandLine.arguments[0], "/usr/bin/security"] {
                    var app: SecTrustedApplication?
                    guard SecTrustedApplicationCreateFromPath(path, &app) == errSecSuccess, let app else { exit(1) }
                    trusted.append(app)
                }
                var access: SecAccess?
                guard SecAccessCreate("Geoffrey OAuth" as CFString, trusted as CFArray, &access) == errSecSuccess,
                      let access else { exit(1) }
                attributes[kSecAttrAccess as String] = access
                status = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
            }
        case "find-generic-password":
            var search = query
            search[kSecReturnData as String] = true
            search[kSecMatchLimit as String] = kSecMatchLimitOne
            var result: CFTypeRef?
            status = SecItemCopyMatching(search as CFDictionary, &result)
            if status == errSecSuccess, let data = result as? Data {
                FileHandle.standardOutput.write(data)
            }
        case "delete-generic-password":
            status = SecItemDelete(query as CFDictionary)
        default:
            exit(2)
        }
        // Match the security CLI's missing-item status without printing secrets.
        if status == errSecItemNotFound { exit(44) }
        if status != errSecSuccess {
            FileHandle.standardError.write(Data("Keychain operation failed (status \(status)).\n".utf8))
            exit(1)
        }
    }
}
