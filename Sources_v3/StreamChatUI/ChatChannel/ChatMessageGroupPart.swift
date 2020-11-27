//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat

@dynamicMemberLookup
public struct _ChatMessageGroupPart<ExtraData: ExtraDataTypes> {
    public let message: _ChatMessage<ExtraData>
    public let parentMessageState: ParentMessageState?
    public let isLastInGroup: Bool

    public var parentMessage: _ChatMessage<ExtraData>? {
        switch parentMessageState {
        case let .loaded(message):
            return message
        default:
            return nil
        }
    }
}

extension _ChatMessageGroupPart {
    public enum ParentMessageState {
        case loading
        case loaded(_ChatMessage<ExtraData>)
    }
}

extension _ChatMessageGroupPart {
    public subscript<T>(dynamicMember keyPath: KeyPath<_ChatMessage<ExtraData>, T>) -> T {
        message[keyPath: keyPath]
    }
}
