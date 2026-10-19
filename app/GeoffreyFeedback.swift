import CryptoKit
import Foundation
import SwiftUI

struct GeoffreyFeedbackContext: Codable, Equatable, Sendable {
    let responseID: String
    let source: String
    let section: String
    let item: String
    init(responseID: String, source: String, section: String, item: String) {
        self.responseID = responseID
        self.source = source
        self.section = section
        self.item = item
    }
    var id: String {
        SHA256.hash(data: Data([responseID, source, section, item].joined(separator: "\u{0}").utf8))
            .map { String(format: "%02x", $0) }.joined()
    }

    enum CodingKeys: String, CodingKey { case id, responseID, source, section, item }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        responseID = try container.decode(String.self, forKey: .responseID)
        source = try container.decode(String.self, forKey: .source)
        section = try container.decode(String.self, forKey: .section)
        item = try container.decode(String.self, forKey: .item)
        guard try container.decode(String.self, forKey: .id) == id else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Feedback context does not match its item.")
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(responseID, forKey: .responseID)
        try container.encode(source, forKey: .source)
        try container.encode(section, forKey: .section)
        try container.encode(item, forKey: .item)
    }
}

struct GeoffreyItemFeedback: Codable, Equatable, Sendable {
    let context: GeoffreyFeedbackContext
    let rating: String?
    let more: Bool
    let note: String
    let updatedAt: String
}

struct GeoffreyFeedbackReply: Decodable, Sendable {
    let ok: Bool
    let record: GeoffreyItemFeedback?
    let error: String?
}

private struct GeoffreyFeedbackRequest: Encodable {
    let context: GeoffreyFeedbackContext
    let rating: String?
    let more: Bool
    let note: String
    let clear: Bool

    enum CodingKeys: String, CodingKey { case context, rating, more, note, clear }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(context, forKey: .context)
        // An explicit null distinguishes note-only feedback from malformed input.
        if let rating { try container.encode(rating, forKey: .rating) }
        else { try container.encodeNil(forKey: .rating) }
        try container.encode(more, forKey: .more)
        try container.encode(note, forKey: .note)
        try container.encode(clear, forKey: .clear)
    }
}

private struct GeoffreyFeedbackError: LocalizedError {
    let errorDescription: String?
}

extension GeoffreyResponse {
    func feedbackContext(section: String, item: String) -> GeoffreyFeedbackContext {
        GeoffreyFeedbackContext(responseID: "\(kind.commandName):\(Int64(date.timeIntervalSince1970 * 1000))",
                                source: title, section: section, item: String(item.prefix(8000)))
    }
}

extension GeoffreyModel {
    private func feedbackCommand(_ arguments: [String]) async throws -> GeoffreyFeedbackReply {
        let engine = geoffreyHome
        let result = await Task.detached {
            GeoffreyCommand().run(executable: engine + "/bin/geoffrey", arguments: ["app-item-feedback"] + arguments,
                                  environment: GeoffreyCommand.environment(engine: engine), timeout: 10)
        }.value
        let reply = try? JSONDecoder().decode(GeoffreyFeedbackReply.self, from: Data(result.output.utf8))
        guard result.status == 0, let reply, reply.ok else {
            throw GeoffreyFeedbackError(errorDescription: reply?.error ?? "Feedback could not be saved or read. Please try again.")
        }
        return reply
    }

    func loadItemFeedback(_ context: GeoffreyFeedbackContext) async throws -> GeoffreyItemFeedback? {
        let reply = try await feedbackCommand(["--id", context.id])
        guard reply.record == nil || reply.record?.context == context else {
            throw GeoffreyFeedbackError(errorDescription: "Previous feedback could not be matched to this item. Please try again.")
        }
        itemFeedback[context.id] = reply.record
        return reply.record
    }

    func saveItemFeedback(_ context: GeoffreyFeedbackContext, rating: String?, more: Bool, note: String, clear: Bool = false) async throws {
        let request = GeoffreyFeedbackRequest(context: context, rating: rating, more: more, note: note, clear: clear)
        let payload = try JSONEncoder().encode(request).base64EncodedString()
        let reply = try await feedbackCommand(["--payload", payload])
        guard clear ? reply.record == nil : reply.record?.context == context else {
            throw GeoffreyFeedbackError(errorDescription: "The feedback save could not be confirmed. Please try again.")
        }
        itemFeedback[context.id] = reply.record
        // Coalesce quick reactions. Saving locally never waits for network backup.
        feedbackBackupTask?.cancel()
        let engine = geoffreyHome
        feedbackBackupTask = Task {
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            guard !Task.isCancelled else { return }
            _ = await Task.detached {
                GeoffreyCommand().run(executable: engine + "/bin/geoffrey", arguments: ["app-sync"],
                                      environment: GeoffreyCommand.environment(engine: engine), timeout: 30)
            }.value
        }
    }
}

struct SectionFeedbackButton: View {
    @EnvironmentObject private var model: GeoffreyModel
    let title: String
    let contexts: [GeoffreyFeedbackContext]
    @State private var showing = false

    private var savedCount: Int {
        contexts.filter { model.itemFeedback[$0.id] != nil }.count
    }

    var body: some View {
        Button { showing = true } label: {
            HStack(spacing: 5) {
                Image(systemName: "bubble.left")
                Text("Feedback")
                if savedCount > 0 { Image(systemName: "checkmark") }
            }
        }
        .font(.caption.weight(.medium))
        .buttonStyle(FeedbackControlStyle())
        .accessibilityLabel("Feedback on \(title)")
        .accessibilityValue(savedCount == 0 ? "No feedback yet" : "Feedback saved for \(savedCount) items")
        .accessibilityHint("Opens feedback for each item in this section")
        .popover(isPresented: $showing, arrowEdge: .bottom) {
            SectionFeedbackPopover(title: title, contexts: contexts, close: { showing = false })
                .environmentObject(model)
        }
    }
}

private struct FeedbackControlStyle: ButtonStyle {
    var selected = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .foregroundStyle(selected ? Color.white : Color.accentColor)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(selected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.accentColor.opacity(selected ? 1 : 0.5), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 6))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.5)
    }
}

private struct SectionFeedbackPopover: View {
    let title: String
    let contexts: [GeoffreyFeedbackContext]
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text("Give feedback on any item below.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: close) { Image(systemName: "xmark") }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Close feedback")
            }
            .padding(18)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(contexts.enumerated()), id: \.element.id) { index, context in
                        if index > 0 { Divider() }
                        ItemFeedbackEditor(context: context)
                    }
                }
                .padding(18)
            }
            .frame(maxHeight: 500)
        }
        .frame(width: 440)
    }
}

private struct ItemFeedbackEditor: View {
    @EnvironmentObject private var model: GeoffreyModel
    let context: GeoffreyFeedbackContext
    @State private var rating: String?
    @State private var more = false
    @State private var note = ""
    @State private var loading = true
    @State private var saving = false
    @State private var issue: String?
    @State private var loadFailed = false
    @State private var confirmation: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(["Briefing", "Overall result"].contains(context.section) ? "This briefing or result" : context.item)
                    .font(.callout.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if loading || saving { ProgressView().controlSize(.small) }
            }
            HStack(spacing: 6) {
                reaction("Good", icon: "hand.thumbsup", selected: rating == "good") {
                    save(rating: rating == "good" ? nil : "good", more: more)
                }
                reaction("Bad", icon: "hand.thumbsdown", selected: rating == "bad") {
                    save(rating: rating == "bad" ? nil : "bad", more: more)
                }
                reaction("More like this", icon: "plus", selected: more) { save(rating: rating, more: !more) }
            }
            TextField("Anything to add? (optional)", text: $note, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Optional feedback note for \(context.item)")
                .onChange(of: note) { _, value in
                    if value.count > 2000 { note = String(value.prefix(2000)) }
                    if value != (model.itemFeedback[context.id]?.note ?? "") { confirmation = nil }
                }
            if let issue {
                Text(issue).font(.caption).foregroundStyle(.red).accessibilityLabel("Feedback error: \(issue)")
            }
            HStack {
                if loadFailed { Button("Try again") { Task { await load() } } }
                else if model.itemFeedback[context.id] != nil {
                    Button("Clear feedback") { save(rating: nil, more: false, clear: true) }
                }
                if let confirmation {
                    Text(confirmation).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Send note") { save(rating: rating, more: more) }
                    .disabled(loadFailed || note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .controlSize(.small)
        }
        .disabled(loading || saving)
        .task { await load() }
    }

    private func reaction(_ title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: selected ? "checkmark" : icon) }
            .font(.caption.weight(.medium))
            .buttonStyle(FeedbackControlStyle(selected: selected))
            .accessibilityAddTraits(selected ? .isSelected : [])
            .disabled(loadFailed)
    }

    private func load() async {
        loading = true
        issue = nil
        do {
            let record = try await model.loadItemFeedback(context)
            rating = record?.rating
            more = record?.more ?? false
            note = record?.note ?? ""
            loadFailed = false
        } catch { issue = error.localizedDescription; loadFailed = true }
        loading = false
    }

    private func save(rating: String?, more: Bool, clear: Bool = false) {
        guard !saving, !loading, !loadFailed else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        // Tapping an already-selected, otherwise empty reaction removes it.
        let shouldClear = clear || (rating == nil && !more && trimmed.isEmpty)
        saving = true
        issue = nil
        confirmation = nil
        Task {
            do {
                try await model.saveItemFeedback(context, rating: rating, more: more, note: trimmed, clear: shouldClear)
                self.rating = shouldClear ? nil : rating
                self.more = shouldClear ? false : more
                note = shouldClear ? "" : trimmed
                confirmation = shouldClear ? "Cleared" : "Saved"
            } catch { issue = error.localizedDescription }
            saving = false
        }
    }
}
