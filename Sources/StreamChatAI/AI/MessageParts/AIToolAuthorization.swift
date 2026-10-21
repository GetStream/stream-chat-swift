//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A sign-in a tool call waits for, such as "Connect Linear", and how it ended.
///
/// The agent's backend writes it on the call's `ai_tool_call` step, which waits with status
/// `awaiting_authorization`, and holds the call until the person signs in at the provider in a
/// browser. Connected, the call goes on; declined, expired or failed, it is cancelled and never
/// runs. The step holds no credential: `url` is the agent's own sign-in page, and the provider
/// hands what it grants to the agent's backend, never to the app.
public struct AIToolAuthorization: Equatable, Sendable {
    /// How the person signs in. An open set: compare against the kinds you know.
    public struct Kind: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        /// A consent at the provider, in a browser (OAuth).
        public static let oauth: Kind = "oauth"
    }

    /// How a sign-in ended. An open set: compare against the statuses you know.
    public struct Status: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        public static let connected: Status = "connected"
        public static let declined: Status = "declined"
        public static let expired: Status = "expired"
        /// The provider or the agent's backend ended it without connecting, such as when the
        /// person came back as another account.
        public static let failed: Status = "failed"
    }

    public var kind: Kind
    /// The provider, such as `linear`.
    public var provider: String
    /// What people call the provider, such as "Linear".
    public var providerName: String?
    /// The question, such as "Connect Linear".
    public var title: String
    /// What signing in means for the person.
    public var message: String?
    /// The sign-in page to open.
    public var url: URL
    /// What binds the sign-in to the first browser that opens it. It goes in the page's
    /// fragment, which no server sees (`launchURL`). Gone once the sign-in is over.
    public var handoffToken: String?
    public var expiresAt: Date?
    /// How it ended, once it did.
    public var status: Status?

    public init(
        kind: Kind = .oauth,
        provider: String,
        providerName: String? = nil,
        title: String,
        message: String? = nil,
        url: URL,
        handoffToken: String? = nil,
        expiresAt: Date? = nil,
        status: Status? = nil
    ) {
        self.kind = kind
        self.provider = provider
        self.providerName = providerName
        self.title = title
        self.message = message
        self.url = url
        self.handoffToken = handoffToken
        self.expiresAt = expiresAt
        self.status = status
    }

    /// The page to open in a web authentication session: `url`, with the handoff token in its
    /// fragment.
    public var launchURL: URL {
        guard let handoffToken, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.fragment = "handoff_token=" + handoffToken
        return components.url ?? url
    }

    /// Reads the step's `authorization`. A sign-in with no title or page asks nothing.
    init?(_ fields: Fields) {
        guard let title = fields.string("title"), let url = fields.string("url").flatMap(URL.init(string:)) else {
            return nil
        }
        self.init(
            kind: fields.string("type").map(Kind.init(rawValue:)) ?? .oauth,
            provider: fields.string("provider") ?? "",
            providerName: fields.string("provider_name"),
            title: title,
            message: fields.string("message"),
            url: url,
            handoffToken: fields.string("handoff_token"),
            expiresAt: fields.date("expires_at"),
            status: fields.string("status").map(Status.init(rawValue:))
        )
    }
}
