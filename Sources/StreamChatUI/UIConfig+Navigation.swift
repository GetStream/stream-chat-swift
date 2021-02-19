//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

public extension _UIConfig {
    struct Navigation {
        internal var navigationBar: ChatNavigationBar<ExtraData>.Type = ChatNavigationBar<ExtraData>.self
        internal var channelListRouter: _ChatChannelListRouter<ExtraData>.Type = _ChatChannelListRouter<ExtraData>.self
        internal var messageListRouter: _ChatMessageListRouter<ExtraData>.Type = _ChatMessageListRouter<ExtraData>.self
        internal var channelDetailRouter: _ChatChannelRouter<ExtraData>.Type = _ChatChannelRouter<ExtraData>.self
        internal var messageActionsRouter: _ChatMessageActionsRouter<ExtraData>.Type = _ChatMessageActionsRouter<ExtraData>.self
    }
}
