//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// One step an AI agent took while replying, such as a round of reasoning or a tool call.
///
/// The agent writes each step as a custom attachment on its reply (`ai_reasoning`,
/// `ai_tool_call`), and the order of the attachments is the order of the steps. The final
/// answer stays in the message text and is shown after them.
///
/// The kinds of step are open: a new one can appear without breaking your code. Read the
/// ones you know through their typed views (`reasoning`, `toolCall`), read kinds of your own
/// with `decode(_:)`, and give anything else a neutral fallback (`AIMessagePartView` shows a
/// placeholder). Decoding is lenient: missing fields get defaults, and a step newer than this
/// SDK understands keeps its payload but has no typed view.
///
/// ```swift
/// let parts = AIMessagePart.parts(from: message.allAttachments.map { ($0.type.rawValue, $0.payload) })
/// for part in parts {
///     if let reasoning = part.reasoning { … }
///     else if let call = part.toolCall { … }
///     else if part.kind == "ai_citation", let citation = try? part.decode(Citation.self) { … }
/// }
/// ```
public final class AIMessagePart: Identifiable, Equatable, Sendable {
    /// What kind of step a part is. It is an open set: compare against the kinds you know
    /// and give the rest a fallback.
    public struct Kind: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        /// The attachment type, such as `ai_reasoning`.
        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        /// A round of the model's reasoning (`ai_reasoning`).
        public static let reasoning: Kind = "ai_reasoning"
        /// A tool the agent called (`ai_tool_call`).
        public static let toolCall: Kind = "ai_tool_call"
    }

    /// The attachment type prefix every AI step uses.
    public static let typePrefix = "ai_"
    /// The newest format version of the built-in kinds this SDK understands.
    public static let supportedVersion = 1

    public let kind: Kind
    /// The step's stable identity, for diffing and animating while it streams. Tool calls
    /// use the model provider's tool-call ID.
    public let id: String
    /// The step's format version (`v`). It changes only when a kind changes incompatibly.
    public let version: Int
    /// The step's attachment payload as JSON, for kinds of your own or fields this SDK does
    /// not read.
    public let payload: Data
    /// The step as a round of reasoning, when it is one this SDK can read.
    public let reasoning: AIReasoningPart?
    /// The step as a tool call, when it is one this SDK can read.
    public let toolCall: AIToolCallPart?

    /// Whether this SDK has a typed view of the step. A step that is not, from a newer agent
    /// or of a kind of your own, still keeps its payload.
    public var isSupported: Bool { reasoning != nil || toolCall != nil }

    /// Decodes the AI steps among a message's attachments, in order. Attachments that are
    /// not AI steps (images, files and so on) are skipped.
    public static func parts(from attachments: [(type: String, payload: Data)]) -> [AIMessagePart] {
        attachments.enumerated().compactMap { index, attachment in
            AIMessagePart(type: attachment.type, payload: attachment.payload, position: index)
        }
    }

    /// Decodes one attachment, or returns `nil` when it is not an AI step.
    /// - Parameter position: The attachment's index, used as the identity of a step that
    ///   carries no ID of its own.
    public init?(type: String, payload: Data, position: Int = 0) {
        guard type.hasPrefix(Self.typePrefix) else { return nil }
        let object = (try? JSONSerialization.jsonObject(with: payload)) as? [String: Any] ?? [:]
        let fields = Fields(object)
        let id = fields.string("id") ?? "\(type)-\(position)"
        let version = fields.int("v") ?? 1
        let kind = Kind(rawValue: type)
        let known = version <= Self.supportedVersion
        self.kind = kind
        self.id = id
        self.version = version
        self.payload = payload
        reasoning = known && kind == .reasoning ? AIReasoningPart(id: id, fields) : nil
        toolCall = known && kind == .toolCall ? AIToolCallPart(id: id, fields) : nil
    }

    /// Decodes the step's payload as a type of your own, for kinds you define.
    public func decode<T: Decodable>(_ type: T.Type = T.self, using decoder: JSONDecoder = JSONDecoder()) throws -> T {
        try decoder.decode(T.self, from: payload)
    }

    public static func == (lhs: AIMessagePart, rhs: AIMessagePart) -> Bool {
        lhs.kind == rhs.kind && lhs.id == rhs.id && lhs.version == rhs.version && lhs.payload == rhs.payload
    }
}
