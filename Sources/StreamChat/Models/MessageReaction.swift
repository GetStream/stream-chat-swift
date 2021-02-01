//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a message reaction. `ChatMessageReaction` is an immutable snapshot of a message
/// reaction entity at the given time.
///
/// - Note: `ChatMessageReaction` is a typealias of `_ChatMessageReaction` with default extra data.
/// If you're using custom extra data, create your own typealias of `_ChatMessageReaction`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChatMessageReaction = _ChatMessageReaction<NoExtraData>

/// A type representing a message reaction. `_ChatMessageReaction` is an immutable snapshot
/// of a message reaction entity at the given time.
///
/// - Note: `_ChatMessageReaction` type is not meant to be used directly. If you're using default extra data,
/// use `ChatMessageReaction` typealias instead. If you're using custom extra data,
/// create your own typealias of `_ChatMessageReaction`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
@dynamicMemberLookup
public struct _ChatMessageReaction<ExtraData: ExtraDataTypes>: Hashable {
    /// The reaction type.
    public let type: MessageReactionType
    
    /// The reaction score.
    public let score: Int
    
    /// The date the reaction was created.
    public let createdAt: Date
    
    /// The date the reaction was last updated.
    public let updatedAt: Date
    
    /// The reaction's extra data.
    public let extraData: ExtraData.MessageReaction
    
    /// The author.
    public let author: _ChatUser<ExtraData.User>
}

extension _ChatMessageReaction {
    public subscript<T>(dynamicMember keyPath: KeyPath<ExtraData.MessageReaction, T>) -> T {
        extraData[keyPath: keyPath]
    }
}

/// You need to make your custom type conforming to this protocol if you want to use it for extending `ChatMessageReaction` entity
/// with your custom additional data.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public protocol MessageReactionExtraData: ExtraData {}
