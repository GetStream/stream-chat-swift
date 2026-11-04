//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Built-in action types dispatched to the host (`BuiltinActionType`).
@available(iOS 17.0, macOS 14.0, *)
enum BuiltinActionType {
    /// Send the user's intent back to the model (`@ToAssistant`, follow-ups, plain buttons).
    static let continueConversation = "continue_conversation"
    /// Open a URL (`@OpenUrl`).
    static let openURL = "open_url"
}

/// A structured action fired by an interactive component (mirrors `ActionEvent`).
///
/// `@Run`, `@Set` and `@Reset` steps are handled by the runtime; conversation and navigation
/// steps (and any custom action types) are forwarded to the host as ``ActionEvent``s.
@available(iOS 17.0, macOS 14.0, *)
struct ActionEvent: Sendable, Hashable {
    /// Action type: ``BuiltinActionType/continueConversation``, ``BuiltinActionType/openURL`` or a custom type.
    var type: String
    /// Action-specific params, e.g. `url` for open-url or `context` for continue-conversation.
    var params: OpenUIObject
    /// The message the model wrote for the action, such as a `@ToAssistant` step's, or the
    /// label of the control when it wrote none.
    var humanFriendlyMessage: String
    /// The label of the control the person used, such as a button's title. A chat shows it as
    /// their message, as the model's words could say something they never chose.
    var label: String
    /// Raw form state at the time of the action.
    var formState: OpenUIObject?
    /// The form that scoped the action, if any.
    var formName: String?

    init(
        type: String,
        params: OpenUIObject = [:],
        humanFriendlyMessage: String,
        label: String = "",
        formState: OpenUIObject? = nil,
        formName: String? = nil
    ) {
        self.type = type
        self.params = params
        self.humanFriendlyMessage = humanFriendlyMessage
        self.label = label
        self.formState = formState
        self.formName = formName
    }

    var isContinueConversation: Bool { type == BuiltinActionType.continueConversation }
    var isOpenURL: Bool { type == BuiltinActionType.openURL }

    /// The URL of an open-url action, when it's a web or email link. The model writes it, so a
    /// link to another app or a phone number is `nil`.
    var url: URL? {
        guard let string = params["url"]?.stringValue, let url = URL(string: string), OpenUILink.isOpenable(url) else {
            return nil
        }
        return url
    }

    /// The `context` of a `@ToAssistant(message, context)` step: any value, passed through unchanged.
    var context: OpenUIValue? {
        params["context"]
    }

    /// The user message sent back to the model for a continue-conversation action, in the OpenUI
    /// message protocol: the visible text, plus a context of what was clicked, the form state and
    /// the step's context (upstream `buildActionUserMessage`).
    var assistantMessage: String {
        var items: [OpenUIValue] = [.string("User clicked: \(humanFriendlyMessage)")]
        if formState != nil || context != nil {
            items.append(.object(formState?.withoutSecrets ?? [:]))
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
