//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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
