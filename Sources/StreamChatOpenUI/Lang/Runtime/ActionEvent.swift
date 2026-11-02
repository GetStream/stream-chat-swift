//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Built-in action types dispatched to the host (`BuiltinActionType`).
@available(iOS 17.0, macOS 14.0, *)
public enum BuiltinActionType {
    /// Send the user's intent back to the model (`@ToAssistant`, follow-ups, plain buttons).
    public static let continueConversation = "continue_conversation"
    /// Open a URL (`@OpenUrl`).
    public static let openURL = "open_url"
}

/// A structured action fired by an interactive component (mirrors `ActionEvent`).
///
/// `@Run`, `@Set` and `@Reset` steps are handled by the runtime; conversation and navigation
/// steps (and any custom action types) are forwarded to the host as ``ActionEvent``s.
@available(iOS 17.0, macOS 14.0, *)
public struct ActionEvent: Sendable, Hashable {
    /// Action type: ``BuiltinActionType/continueConversation``, ``BuiltinActionType/openURL`` or a custom type.
    public var type: String
    /// Action-specific params, e.g. `url` for open-url or `context` for continue-conversation.
    public var params: OpenUIObject
    /// Human readable label (e.g. the button label) — shown as the user's message in a chat.
    public var humanFriendlyMessage: String
    /// Raw form state at the time of the action.
    public var formState: OpenUIObject?
    /// The form that scoped the action, if any.
    public var formName: String?

    public init(type: String, params: OpenUIObject = [:], humanFriendlyMessage: String, formState: OpenUIObject? = nil, formName: String? = nil) {
        self.type = type
        self.params = params
        self.humanFriendlyMessage = humanFriendlyMessage
        self.formState = formState
        self.formName = formName
    }

    public var isContinueConversation: Bool { type == BuiltinActionType.continueConversation }
    public var isOpenURL: Bool { type == BuiltinActionType.openURL }

    /// The URL of an open-url action.
    public var url: URL? {
        guard let string = params["url"]?.stringValue else { return nil }
        return URL(string: string)
    }

    /// The `context` of a `@ToAssistant(message, context)` step: any value, passed through unchanged.
    public var context: OpenUIValue? {
        params["context"]
    }

    /// The user message sent back to the model for a continue-conversation action, in the OpenUI
    /// message protocol: the visible text, plus a context of what was clicked, the form state and
    /// the step's context (upstream `buildActionUserMessage`).
    public var assistantMessage: String {
        var items: [OpenUIValue] = [.string("User clicked: \(humanFriendlyMessage)")]
        if formState != nil || context != nil {
            items.append(.object(formState ?? [:]))
        }
        if let context {
            items.append(context)
        }
        let message = MessageEnvelope.build(content: humanFriendlyMessage, context: .array(items))
        // No message: stored without the content line.
        guard humanFriendlyMessage.isEmpty, let newline = message.firstIndex(of: "\n") else { return message }
        return String(message[message.index(after: newline)...])
    }
}
