//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UICollectionViewLayout

public extension _UIConfig {
    struct ChannelListUI {
        internal var channelCollectionView: ChatChannelListCollectionView.Type = ChatChannelListCollectionView.self
        internal var channelCollectionLayout: UICollectionViewLayout.Type = ChatChannelListCollectionViewLayout.self
        internal var channelListSwipeableItemView: _ChatChannelSwipeableListItemView<ExtraData>.Type =
            _ChatChannelSwipeableListItemView<ExtraData>.self
        /// A  `ChatChannelSwipeableListItemView` subclass view that shows channel information.
        internal var channelListItemView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self
        /// A `UICollectionViewCell` subclass that shows channel information.
        internal var channelViewCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
            _ChatChannelListCollectionViewCell<ExtraData>.self
        /// A button used for creating new channels.
        internal var newChannelButton: UIButton.Type = _ChatChannelCreateNewButton<ExtraData>.self
        internal var channelNamer: ChatChannelNamer.Type = ChatChannelNamer.self
        internal var channelListItemSubviews = ChannelListItemSubviews()
    }
    
    struct ChannelListItemSubviews {
        /// A view that shows a user avatar including an indicator of the user presence (online/offline).
        internal var avatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self
        /// A type for the view that shows a number of unread messages in channel.
        internal var unreadCountView: _ChatChannelUnreadCountView<ExtraData>.Type = _ChatChannelUnreadCountView<ExtraData>.self
        /// A type for the view that shows a read/unread status of the last message in channel.
        internal var readStatusView: _ChatChannelReadStatusCheckmarkView<ExtraData>.Type =
            _ChatChannelReadStatusCheckmarkView<ExtraData>.self
        /// A type for the view used as an online activity indicator for avatars.
        internal var onlineIndicator: UIView.Type = _ChatOnlineIndicatorView<ExtraData>.self
    }
}

// MARK: - CurrentUser

public extension _UIConfig {
    struct CurrentUserUI {
        internal var currentUserViewAvatarView: _CurrentChatUserAvatarView<ExtraData>.Type = _CurrentChatUserAvatarView<ExtraData>
            .self
        internal var avatarView: ChatAvatarView.Type = ChatAvatarView.self
    }
}
