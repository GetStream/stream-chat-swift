//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// What a person did in a reply's generated UI that the agent should hear about, such as
/// tapping a place or submitting a form.
///
/// Send it as their next message: `label` is its text, what people read in the conversation,
/// and `customData` holds the action for the agent.
///
/// ```swift
/// try await chat.sendMessage(with: action.label, extraData: action.customData)
/// ```
public struct AIUIAction: Equatable, Sendable {
    /// The custom field of the person's message that holds the action.
    public static let customDataKey = "ai_ui_action"

    /// The reply whose UI it came from.
    public var messageID: String
    /// The format of that UI.
    public var format: AIUIFormat
    /// What happened, such as an event of an app's component (`ask_about`) or OpenUI's
    /// `continue_conversation`.
    public var name: String
    /// What the person did, in their words, such as "Tell me more about St. Naum".
    public var label: String
    /// The details in the format's own shape, such as what was chosen and a form's values.
    public var payload: [String: RawJSON]

    public init(messageID: String, format: AIUIFormat, name: String, label: String, payload: [String: RawJSON] = [:]) {
        self.messageID = messageID
        self.format = format
        self.name = name
        self.label = label
        self.payload = payload
    }

    /// The action as the JSON object an agent's backend reads.
    public var json: [String: RawJSON] {
        [
            "v": .number(1),
            "message_id": .string(messageID),
            "format": .string(format.rawValue),
            "name": .string(name),
            "payload": .dictionary(payload)
        ]
    }

    /// The action as the custom data of the person's message, under `ai_ui_action`.
    public var customData: [String: RawJSON] {
        [Self.customDataKey: .dictionary(json)]
    }
}
