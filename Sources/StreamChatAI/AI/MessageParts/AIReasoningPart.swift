//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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
