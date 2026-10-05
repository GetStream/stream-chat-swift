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

/// A round of the model's reasoning.
public struct AIReasoningPart: Identifiable, Equatable, Sendable {
    /// Where a round of reasoning is. An open set: compare against the statuses you know.
    public struct Status: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        /// The model is still thinking.
        public static let streaming: Status = "streaming"
        /// The round is over.
        public static let completed: Status = "completed"
    }

    public var id: String
    /// Defaults to `completed` when the agent sends none.
    public var status: Status
    /// A one-line summary of the reasoning, once it is done.
    public var summary: String?
    /// A capped excerpt: the latest thoughts while streaming, the opening once done. The
    /// full reasoning, when an app has it, arrives separately.
    public var preview: String?
    public var durationMS: Int?

    public var duration: TimeInterval? { durationMS.map { TimeInterval($0) / 1000 } }
    public var isStreaming: Bool { status == .streaming }

    public init(id: String, status: Status, summary: String? = nil, preview: String? = nil, durationMS: Int? = nil) {
        self.id = id
        self.status = status
        self.summary = summary
        self.preview = preview
        self.durationMS = durationMS
    }

    init(id: String, _ fields: Fields) {
        self.init(
            id: id,
            status: fields.string("status").map(Status.init(rawValue:)) ?? .completed,
            summary: fields.string("summary"),
            preview: fields.string("preview"),
            durationMS: fields.int("duration_ms")
        )
    }
}

/// A tool the agent called, run by the agent's backend or by a person's device.
public struct AIToolCallPart: Identifiable, Equatable, Sendable {
    /// Where a tool call is. An open set: compare against the statuses you know, and treat
    /// the rest as still in progress.
    public struct Status: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        public static let running: Status = "running"
        /// Waiting for the targeted person to allow or decline the call. Its `approval` says
        /// what to ask them.
        public static let awaitingApproval: Status = "awaiting_approval"
        /// Waiting for the targeted device to run the tool and send its result.
        public static let awaitingClient: Status = "awaiting_client"
        public static let completed: Status = "completed"
        public static let failed: Status = "failed"
        public static let cancelled: Status = "cancelled"

        /// Whether the call has finished, one way or another.
        public var isFinished: Bool { self == .completed || self == .failed || self == .cancelled }
    }

    /// Who runs a tool. An open set: compare against the executors you know.
    public struct Executor: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        /// The agent's backend.
        public static let server: Executor = "server"
        /// A person's device.
        public static let client: Executor = "client"
    }

    /// The model provider's tool-call ID. A device's result is matched against it.
    public var id: String
    public var name: String
    /// What the call is doing, in words for people, such as "Checking your location".
    public var displayTitle: String?
    /// Defaults to `running` when the agent sends none.
    public var status: Status
    /// Defaults to `server` when the agent sends none.
    public var executor: Executor
    /// The person whose device must run a client tool.
    public var targetUserID: String?
    /// The install that must run a client tool, from the custom data of the person's
    /// triggering message.
    public var targetClientID: String?
    /// The call's arguments as JSON, present for client tools, which need them to run.
    /// Every channel member can see them.
    public var arguments: Data?
    /// A short, shareable outcome, such as "Found your location".
    public var summary: String?
    public var durationMS: Int?
    /// What the call asks the person it waits for before it runs, and how they answered,
    /// when its tool asks first.
    public var approval: AIToolApproval?

    public var duration: TimeInterval? { durationMS.map { TimeInterval($0) / 1000 } }

    /// Whether the person declined the call, so it never ran.
    public var isDeclined: Bool { approval?.decision == .declined }

    public init(
        id: String,
        name: String,
        displayTitle: String? = nil,
        status: Status,
        executor: Executor = .server,
        targetUserID: String? = nil,
        targetClientID: String? = nil,
        arguments: Data? = nil,
        summary: String? = nil,
        durationMS: Int? = nil,
        approval: AIToolApproval? = nil
    ) {
        self.id = id
        self.name = name
        self.displayTitle = displayTitle
        self.status = status
        self.executor = executor
        self.targetUserID = targetUserID
        self.targetClientID = targetClientID
        self.arguments = arguments
        self.summary = summary
        self.durationMS = durationMS
        self.approval = approval
    }

    init(id: String, _ fields: Fields) {
        self.init(
            id: id,
            name: fields.string("name") ?? "",
            displayTitle: fields.string("display_title"),
            status: fields.string("status").map(Status.init(rawValue:)) ?? .running,
            executor: fields.string("executor").map(Executor.init(rawValue:)) ?? .server,
            targetUserID: fields.string("target_user_id"),
            targetClientID: fields.string("target_client_id"),
            arguments: fields.json("arguments"),
            summary: fields.string("summary"),
            durationMS: fields.int("duration_ms"),
            approval: fields.fields("approval").flatMap(AIToolApproval.init)
        )
    }

    /// Whether this call is waiting for this device: a client tool, still awaiting its
    /// result, targeted at this person and this install.
    public func isAwaiting(userID: String, clientID: String) -> Bool {
        executor == .client && status == .awaitingClient && targetUserID == userID && targetClientID == clientID
    }

    /// Whether this call is waiting for this person to allow it, on this device: still
    /// awaiting approval, targeted at this person, and at this install when it names one
    /// (a client tool does; a server tool's question may be answered from any of their
    /// devices).
    public func isAwaitingApproval(userID: String, clientID: String) -> Bool {
        status == .awaitingApproval && approval != nil && targetUserID == userID
            && (targetClientID == nil || targetClientID == clientID)
    }

    /// Decodes the arguments into a type of your own.
    public func decodeArguments<T: Decodable>(as type: T.Type = T.self) throws -> T {
        try JSONDecoder().decode(T.self, from: arguments ?? Data("{}".utf8))
    }
}

/// What a tool call asks the person it waits for before it runs, such as "Share your
/// location?", and how they answered.
///
/// The agent's backend writes it on the call's `ai_tool_call` step, which waits with status
/// `awaiting_approval`, and holds the call until the person answers. Allowed, the call goes
/// on (a client tool then awaits the device); declined, it is cancelled and never runs.
public struct AIToolApproval: Equatable, Sendable {
    /// How the person answered. An open set: compare against the decisions you know.
    public struct Decision: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        public static let allowed: Decision = "allowed"
        public static let declined: Decision = "declined"
    }

    /// The question, such as "Share your location?".
    public var title: String
    /// What allowing it shares or does, such as "Only your city is shared."
    public var message: String?
    /// The agent's own words for why it wants the call, such as "to check the local
    /// weather".
    public var reason: String?
    /// The label of the button that allows the call. Defaults to "Allow".
    public var allowTitle: String
    /// The label of the button that declines it. Defaults to "Don't Allow".
    public var declineTitle: String
    /// How the person answered, once they did.
    public var decision: Decision?

    public init(
        title: String,
        message: String? = nil,
        reason: String? = nil,
        allowTitle: String? = nil,
        declineTitle: String? = nil,
        decision: Decision? = nil
    ) {
        self.title = title
        self.message = message
        self.reason = reason
        self.allowTitle = allowTitle ?? L10n.ToolApproval.allow
        self.declineTitle = declineTitle ?? L10n.ToolApproval.decline
        self.decision = decision
    }

    /// Reads the step's `approval`. A question with no title asks nothing.
    init?(_ fields: Fields) {
        guard let title = fields.string("title") else { return nil }
        self.init(
            title: title,
            message: fields.string("message"),
            reason: fields.string("reason"),
            allowTitle: fields.string("allow_title"),
            declineTitle: fields.string("decline_title"),
            decision: fields.string("decision").map(Decision.init(rawValue:))
        )
    }
}

/// Lenient reads from a JSON object: a field of the wrong type reads as missing.
struct Fields {
    let object: [String: Any]

    init(_ object: [String: Any]) { self.object = object }

    func string(_ key: String) -> String? {
        guard let value = object[key] as? String, !value.isEmpty else { return nil }
        return value
    }

    func int(_ key: String) -> Int? {
        guard let number = object[key] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        return number.intValue
    }

    func fields(_ key: String) -> Fields? {
        (object[key] as? [String: Any]).map(Fields.init)
    }

    func json(_ key: String) -> Data? {
        guard let value = object[key], !(value is NSNull), JSONSerialization.isValidJSONObject(value) else { return nil }
        return try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    }
}
