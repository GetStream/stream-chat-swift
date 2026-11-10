//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What the agent says it is doing while it answers, besides what its reply shows, such as
/// thinking or checking external sources. Stream Chat's AI indicator events carry it:
///
/// ```swift
/// feed.update(activity: AIAgentActivity(state: .init(rawValue: event.state.rawValue), text: event.aiMessage))
/// ```
@available(iOS 15.0, macOS 12.0, *)
public struct AIAgentActivity: Hashable, Sendable {
    /// What the agent is doing. It is an open set: compare against the states you know. Their
    /// raw values are those of Stream Chat's AI indicator.
    public struct State: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        /// Thinking about its answer.
        public static let thinking: State = "AI_STATE_THINKING"
        /// Looking something up, such as on the web or with a tool.
        public static let checkingExternalSources: State = "AI_STATE_EXTERNAL_SOURCES"
        /// Writing its answer.
        public static let generating: State = "AI_STATE_GENERATING"
        /// It couldn't answer.
        public static let error: State = "AI_STATE_ERROR"
    }

    /// What the agent is doing.
    public var state: State
    /// What it says about it, such as "Searching the web", or why it couldn't answer.
    public var text: String?

    public init(state: State, text: String? = nil) {
        self.state = state
        self.text = text
    }
}
