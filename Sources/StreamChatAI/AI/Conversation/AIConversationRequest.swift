//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What the person asks of the agent, which an ``AIConversation`` hands to its
/// ``AIConversationTransport``.
@available(iOS 15.0, macOS 12.0, *)
public struct AIConversationRequest<Message: AIMessage> {
    /// What the person asks for.
    public typealias Kind = AIConversationRequestKind

    /// What the person asks for.
    public var kind: Kind
    /// What the person wrote. When a reply is written again, the message it answers says it.
    public var text: String
    /// The files the person picked, on this device, to upload with their message.
    public var attachments: [URL]
    /// The option the person picked in the composer, such as thinking harder.
    public var chatOption: ChatOption?
    /// The message it is about: the reply to write again, or the person's message they edited.
    public var message: Message?
    /// An id for the person's message. A transport that creates the message with it lets the
    /// conversation find its copy by it. A retry of the request keeps it.
    public var messageID: String

    public init(
        kind: Kind,
        text: String,
        attachments: [URL] = [],
        chatOption: ChatOption? = nil,
        message: Message? = nil,
        messageID: String = UUID().uuidString
    ) {
        self.kind = kind
        self.text = text
        self.attachments = attachments
        self.chatOption = chatOption
        self.message = message
        self.messageID = messageID
    }
}

/// What the person asks for in an ``AIConversationRequest``. It is an open set: compare against the
/// kinds you know, and treat the rest as a new message.
@available(iOS 15.0, macOS 12.0, *)
public struct AIConversationRequestKind: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { rawValue = value }
    public var description: String { rawValue }

    /// A new message from the person.
    public static let message: AIConversationRequestKind = "message"
    /// A new reply in place of the request's `message`, which is a reply, and of those after
    /// it. Without `message`, a reply to the latest message, which has none, such as after the
    /// agent couldn't answer it.
    public static let regenerate: AIConversationRequestKind = "regenerate"
    /// The person changed the request's `message`, one of theirs, to say its `text`: it is
    /// answered again, in place of the replies after it.
    public static let edit: AIConversationRequestKind = "edit"
}
