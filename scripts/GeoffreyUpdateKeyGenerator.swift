import CryptoKit
import Foundation

@main
struct GeoffreyUpdateKeyGenerator {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw NSError(domain: "GeoffreyRelease", code: 2, userInfo: [NSLocalizedDescriptionKey: "Provide one private-key output path."])
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
        let manager = FileManager.default
        guard !manager.fileExists(atPath: output.path) else {
            throw NSError(domain: "GeoffreyRelease", code: 3, userInfo: [NSLocalizedDescriptionKey: "The private-key output already exists; it was not overwritten."])
        }
        let key = Curve25519.Signing.PrivateKey()
        try manager.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try (key.rawRepresentation.base64EncodedString() + "\n").write(to: output, atomically: true, encoding: .utf8)
        try manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: output.path)
        print(key.publicKey.rawRepresentation.base64EncodedString())
    }
}
