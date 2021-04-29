//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

public extension _Components {
    struct Navigation {
        public var navigationBar: ChatNavigationBar.Type = ChatNavigationBar.self
        public var channelListRouter: _ChatChannelListRouter<ExtraData>.Type = _ChatChannelListRouter<ExtraData>.self
        public var messageListRouter: _ChatMessageListRouter<ExtraData>.Type = _ChatMessageListRouter<ExtraData>.self
        public var messageActionsRouter: _ChatMessageActionsRouter<ExtraData>.Type = _ChatMessageActionsRouter<ExtraData>.self
    }
}
