//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object that provides a way to transform Stream Chat models.
///
/// Only some data can be changed. The method `mapped` is used to create a new object from existing data.
/// All transform functions have default implementation, so you can override only the ones you need.
///
/// **Note:** When using `mapped()` method, you need to provide all the properties of the existing object.
/// Or you can pass `nil` and that will erase the existing value.
///
/// Example:
/// ```
/// class CustomStreamModelsTransformer: StreamModelsTransformer {
///     func transform(channel: ChatChannel) -> ChatChannel {
///         channel.mapped(
///             name: "Hey!",
///             imageURL: channel.imageURL,
///             extraData: channel.extraData
///         )
///     }
///  ```
public protocol StreamModelsTransformer {
    /// Transforms the given `ChatChannel` object.
    func transform(channel: ChatChannel) -> ChatChannel
    /// Transforms the given `ChatMessage` object.
    func transform(message: ChatMessage) -> ChatMessage
    /// Transforms the given `NewMessageTransformableInfo` object when creating a new message.
    func transform(newMessageInfo: NewMessageTransformableInfo) -> NewMessageTransformableInfo
}

/// Default implementations.
extension StreamModelsTransformer {
    func transform(channel: ChatChannel) -> ChatChannel {
        channel
    }

    func transform(message: ChatMessage) -> ChatMessage {
        message
    }

    func transform(newMessageInfo: NewMessageTransformableInfo) -> NewMessageTransformableInfo {
        newMessageInfo
    }
}

/// The information that can be transformed when creating a new message.
public struct NewMessageTransformableInfo {
    public var text: String
    public var attachments: [AnyAttachmentPayload]
    public var extraData: [String: RawJSON]

    init(
        text: String,
        attachments: [AnyAttachmentPayload],
        extraData: [String: RawJSON]
    ) {
        self.text = text
        self.attachments = attachments
        self.extraData = extraData
    }

    public func mapped(
        text: String,
        attachments: [AnyAttachmentPayload],
        extraData: [String: RawJSON]
    ) -> NewMessageTransformableInfo {
        .init(
            text: text,
            attachments: attachments,
            extraData: extraData
        )
    }
}
