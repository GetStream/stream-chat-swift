//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// The UI a reply shows in place of its text, which the agent wrote in a format such as OpenUI.
///
/// The agent's backend writes it in the reply's `ai_ui` custom field. The reply's text stays
/// readable on its own, for wherever the UI can't show, such as a push notification or an app
/// without a renderer for the format:
///
/// ```json
/// "ai_ui": { "v": 1, "format": "openui", "status": "streaming", "content": "root = Card([title])" }
/// ```
///
/// ```swift
/// var uiDocument: AIUIDocument? { AIUIDocument(customData: message.extraData) }
/// ```
public struct AIUIDocument: Equatable, Sendable {
    /// The custom field of a message that holds its document.
    public static let customDataKey = "ai_ui"
    /// The newest version of the `ai_ui` field this SDK reads.
    public static let supportedVersion = 1

    /// The format it is written in.
    public var format: AIUIFormat
    /// The format's version, when the agent names one.
    public var version: String?
    /// Whether the agent is still writing it.
    public var isStreaming: Bool
    /// The document in its format's own shape: a program's text, or JSON.
    public var content: RawJSON

    public init(format: AIUIFormat, version: String? = nil, isStreaming: Bool = false, content: RawJSON) {
        self.format = format
        self.version = version
        self.isStreaming = isStreaming
        self.content = content
    }

    /// Reads the document a message carries in its custom data, or returns `nil` when it
    /// carries none this SDK can read.
    public init?(customData: [String: RawJSON]) {
        guard case let .dictionary(fields)? = customData[Self.customDataKey],
              let format = fields["format"]?.stringValue, !format.isEmpty,
              let content = fields["content"], content != .nil else {
            return nil
        }
        if let version = fields["v"]?.numberValue, version > Double(Self.supportedVersion) {
            return nil
        }
        let version = fields["version"]?.stringValue
        self.init(
            format: AIUIFormat(rawValue: format),
            version: version?.isEmpty == false ? version : nil,
            isStreaming: fields["status"]?.stringValue == "streaming",
            content: content
        )
    }

    /// The content when it is text, such as an OpenUI program.
    public var text: String? {
        guard case let .string(text) = content else { return nil }
        return text
    }
}
