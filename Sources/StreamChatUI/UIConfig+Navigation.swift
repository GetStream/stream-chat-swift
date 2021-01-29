//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

public extension _UIConfig {
    struct Navigation {
        public var navigationBar: ChatNavigationBar<ExtraData>.Type = ChatNavigationBar<ExtraData>.self
        public var channelListRouter: _ChatChannelListRouter<ExtraData>.Type = _ChatChannelListRouter<ExtraData>.self
        public var messageListRouter: _ChatMessageListRouter<ExtraData>.Type = _ChatMessageListRouter<ExtraData>.self
        public var channelDetailRouter: _ChatChannelRouter<ExtraData>.Type = _ChatChannelRouter<ExtraData>.self
        public var messageActionsRouter: _ChatMessageActionsRouter<ExtraData>.Type = _ChatMessageActionsRouter<ExtraData>.self
    }
}
