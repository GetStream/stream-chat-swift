//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// One part of a message sent to an agent.
public protocol MessagePart {}

/// A plain text message part.
public struct TextPart: MessagePart {
    /// The text content.
    public let text: String

    /// Creates a text part.
    /// Use this for user prompts and agent replies.
    public init(_ text: String) {
        self.text = text
    }
}

/// A structured JSON message part.
public struct DataPart: MessagePart {
    /// The JSON payload.
    public let data: (any Sendable)?

    /// Creates a data part.
    /// Use this for structured payloads such as A2UI messages.
    public init(_ data: (any Sendable)?) {
        self.data = data
    }
}

/// An image message part.
public struct ImagePart: MessagePart {
    /// Raw image bytes, when the image is inline.
    public let bytes: Data?

    /// Base64-encoded image data, when the image is inline.
    public let base64: String?

    /// The location of the image, when it is hosted remotely.
    public let url: URL?

    /// The MIME type of the image.
    public let mimeType: String

    private init(bytes: Data? = nil, base64: String? = nil, url: URL? = nil, mimeType: String) {
        self.bytes = bytes
        self.base64 = base64
        self.url = url
        self.mimeType = mimeType
    }

    /// Creates an image part from raw bytes.
    public static func bytes(_ bytes: Data, mimeType: String) -> ImagePart {
        ImagePart(bytes: bytes, mimeType: mimeType)
    }

    /// Creates an image part from base64-encoded data.
    public static func base64(_ base64: String, mimeType: String) -> ImagePart {
        ImagePart(base64: base64, mimeType: mimeType)
    }

    /// Creates an image part that references a remote URL.
    public static func url(_ url: URL, mimeType: String) -> ImagePart {
        ImagePart(url: url, mimeType: mimeType)
    }
}

/// An entry of the conversation between the user and the agent.
public protocol Message {}

/// A message authored by the user.
public struct UserMessage: Message {
    /// The parts making up the message.
    public let parts: [MessagePart]

    /// The text of the message, with all text parts joined.
    public let text: String

    /// Creates a user message from parts.
    /// Text parts are joined for display and history.
    public init(_ parts: [MessagePart]) {
        self.parts = parts
        self.text = parts.compactMap { ($0 as? TextPart)?.text }.joined(separator: "\n")
    }

    /// Creates a user message from a string.
    public static func text(_ text: String) -> UserMessage {
        UserMessage([TextPart(text)])
    }
}

/// A message carrying renderer-to-agent A2UI events.
///
/// Used for user actions, function responses and renderer errors, which travel
/// as A2UI data parts rather than as text.
public struct UiInteractionMessage: Message {
    /// The A2UI messages to deliver.
    public let rendererMessages: [RendererMessage]

    /// An optional human-readable summary for conversation history.
    public let text: String?

    /// Creates a UI interaction message.
    /// The summary is taken from the action's `userMessage` when present.
    public init(rendererMessages: [RendererMessage], text: String? = nil) {
        self.rendererMessages = rendererMessages
        self.text = text
    }
}

/// A text response from the agent.
public struct AiTextMessage: Message {
    /// The parts making up the response.
    public let parts: [MessagePart]

    /// The text of the response.
    public let text: String

    /// Creates an agent text message from parts.
    public init(_ parts: [MessagePart]) {
        self.parts = parts
        self.text = parts.compactMap { ($0 as? TextPart)?.text }.joined(separator: "\n")
    }

    /// Creates an agent text message from a string.
    public static func text(_ text: String) -> AiTextMessage {
        AiTextMessage([TextPart(text)])
    }
}

/// A surface rendered as part of the conversation.
public struct AiUiMessage: Message {
    /// The definition of the rendered surface.
    public let definition: UiDefinition

    /// The surface this message renders.
    public let surfaceId: String

    /// A textual description of the surface for agent context.
    public let text: String

    /// Creates a UI message for a surface.
    /// The description lets a stateless agent understand what is on screen.
    public init(definition: UiDefinition) {
        self.definition = definition
        self.surfaceId = definition.surfaceId
        self.text = definition.asContextDescriptionText()
    }
}

/// An internal note in the conversation log.
public struct InternalMessage: Message {
    /// The note's text.
    public let text: String

    /// Creates an internal message.
    /// Use this for diagnostics that are not part of the agent exchange.
    public init(_ text: String) {
        self.text = text
    }
}
