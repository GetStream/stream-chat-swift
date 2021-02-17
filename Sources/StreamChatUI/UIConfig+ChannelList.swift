//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UICollectionViewLayout

public extension _UIConfig {
    struct ChannelListUI {
        public var channelCollectionView: ChatChannelListCollectionView.Type = ChatChannelListCollectionView.self
        public var channelCollectionLayout: UICollectionViewLayout.Type = ChatChannelListCollectionViewLayout.self
        public var channelListSwipeableItemView: _ChatChannelSwipeableListItemView<ExtraData>.Type =
            _ChatChannelSwipeableListItemView<ExtraData>.self
        public var channelListItemView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self
        public var channelViewCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
            _ChatChannelListCollectionViewCell<ExtraData>.self
        /// A button used for creating new channels.
        public var newChannelButton: UIButton.Type = _ChatChannelCreateNewButton<ExtraData>.self
        public var channelNamer: ChatChannelNamer.Type = ChatChannelNamer.self
        public var channelListItemSubviews = ChannelListItemSubviews()
    }
    
    struct ChannelListItemSubviews {
        public var avatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self
        public var unreadCountView: _ChatChannelUnreadCountView<ExtraData>.Type = _ChatChannelUnreadCountView<ExtraData>.self
        /// A type for the view that shows a read/unread status of the last message in channel.
        public var readStatusView: _ChatChannelReadStatusCheckmarkView<ExtraData>.Type =
            _ChatChannelReadStatusCheckmarkView<ExtraData>.self
        /// A type for the view used as an online activity indicator for avatars.
        public var onlineIndicator: UIView.Type = _ChatOnlineIndicatorView<ExtraData>.self
    }
}

// MARK: - CurrentUser

public extension _UIConfig {
    struct CurrentUserUI {
        public var currentUserViewAvatarView: _CurrentChatUserAvatarView<ExtraData>.Type = _CurrentChatUserAvatarView<ExtraData>
            .self
        public var avatarView: ChatAvatarView.Type = ChatAvatarView.self
    }
}
