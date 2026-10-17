import CryptoKit
import Foundation

@main
struct GeoffreyUpdaterTests {
    static func main() throws {
        let privateKey = Curve25519.Signing.PrivateKey()
        let payload = GeoffreyUpdatePayload(
            schemaVersion: 1,
            version: "0.14.0",
            build: 16,
            publishedAt: "2026-10-16T12:00:00Z",
            minimumMacOS: "14.0",
            releaseNotes: "A verified update.",
            archive: GeoffreyUpdateArchive(
                url: "https://github.com/hammbino/Geoffrey_Public/releases/download/v0.14.0/Geoffrey.zip",
                sha256: String(repeating: "a", count: 64),
                bytes: 1_024
            )
        )
        let payloadData = try JSONEncoder().encode(payload)
        let signature = try privateKey.signature(for: payloadData)
        let envelope = GeoffreySignedUpdateEnvelope(
            payload: payloadData.base64EncodedString(),
            signature: signature.base64EncodedString()
        )
        let envelopeData = try JSONEncoder().encode(envelope)
        let verified = try GeoffreyUpdateVerifier.verifyEnvelope(
            envelopeData,
            publicKeyBase64: privateKey.publicKey.rawRepresentation.base64EncodedString()
        )
        expect(verified == payload, "valid signed update")
        expect(GeoffreyUpdateVerifier.isNewer(candidateVersion: "0.14.0", candidateBuild: 16, currentVersion: "0.13.0", currentBuild: 15), "new version")
        expect(GeoffreyUpdateVerifier.isNewer(candidateVersion: "0.14.0", candidateBuild: 17, currentVersion: "0.14.0", currentBuild: 16), "new build")
        expect(!GeoffreyUpdateVerifier.isNewer(candidateVersion: "0.13.9", candidateBuild: 99, currentVersion: "0.14.0", currentBuild: 16), "version beats build")
        expect(GeoffreyUpdateVerifier.versionAtLeast("15.0.1", minimum: "14.0"), "minimum system version")
        expect(GeoffreyUpdateVerifier.archiveEntriesAreSafe(["Geoffrey.app/", "Geoffrey.app/Contents/MacOS/Geoffrey"]), "safe archive paths")
        expect(!GeoffreyUpdateVerifier.archiveEntriesAreSafe(["Geoffrey.app/Contents/../../outside"]), "archive traversal")
        expect(!GeoffreyUpdateVerifier.archiveEntriesAreSafe(["Other.app/Contents/MacOS/Other"]), "unexpected top-level app")

        var changed = envelopeData
        changed[changed.startIndex] ^= 1
        expectThrows("tampered envelope") {
            _ = try GeoffreyUpdateVerifier.verifyEnvelope(
                changed,
                publicKeyBase64: privateKey.publicKey.rawRepresentation.base64EncodedString()
            )
        }

        let unsafe = GeoffreyUpdatePayload(
            schemaVersion: 1,
            version: "0.14.0",
            build: 16,
            publishedAt: "2026-10-16T12:00:00Z",
            minimumMacOS: "14.0",
            releaseNotes: "Unsafe URL",
            archive: GeoffreyUpdateArchive(url: "http://example.com/Geoffrey.zip", sha256: String(repeating: "a", count: 64), bytes: 1)
        )
        let unsafeData = try JSONEncoder().encode(unsafe)
        let unsafeEnvelope = GeoffreySignedUpdateEnvelope(
            payload: unsafeData.base64EncodedString(),
            signature: try privateKey.signature(for: unsafeData).base64EncodedString()
        )
        expectThrows("non-HTTPS archive") {
            _ = try GeoffreyUpdateVerifier.verifyEnvelope(
                JSONEncoder().encode(unsafeEnvelope),
                publicKeyBase64: privateKey.publicKey.rawRepresentation.base64EncodedString()
            )
        }

        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("Geoffrey updater digest".utf8).write(to: temporary)
        defer { try? FileManager.default.removeItem(at: temporary) }
        try expect(GeoffreyUpdateVerifier.sha256(of: temporary) == "f1407704904db2f8d7ae2dce25882052a953a66db6df8f9a238aec52ff3e7064", "streamed archive digest")

        if CommandLine.arguments.count == 3 {
            let externalEnvelope = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
            let externalPublicKey = CommandLine.arguments[2]
            let external = try GeoffreyUpdateVerifier.verifyEnvelope(externalEnvelope, publicKeyBase64: externalPublicKey)
            expect(external.schemaVersion == 1 && external.archive.url.hasPrefix("https://"), "release signer compatibility")
        }
        print("Geoffrey updater tests passed.")
    }

    private static func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) rethrows {
        guard try condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }

    private static func expectThrows(_ message: String, _ work: () throws -> Void) {
        do {
            try work()
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        } catch { }
    }
}
