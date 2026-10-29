//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

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
