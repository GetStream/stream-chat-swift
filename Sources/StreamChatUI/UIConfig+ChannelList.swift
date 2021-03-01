//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UICollectionViewLayout

public extension _UIConfig {
    struct ChannelListUI {
        /// The collection view of the Channel List.
        public var channelCollectionView: ChatChannelListCollectionView.Type = ChatChannelListCollectionView.self

        /// The collection view layout of the Channel List.
        public var channelCollectionLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self

        /// The Cell Separator View.
        public var channelCellSeparatorReusableView: UICollectionReusableView.Type = _CellSeparatorReusableView<ExtraData>.self

        /// The base view of the channel list item to support swipeable gestures.
        public var channelListSwipeableItemView: _ChatChannelSwipeableListItemView<ExtraData>.Type =
            _ChatChannelSwipeableListItemView<ExtraData>.self

        /// A `ChatChannelSwipeableListItemView` subclass view that shows channel information.
        public var channelListItemView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self

        /// A `UICollectionViewCell` subclass that shows channel information.
        public var channelViewCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
            _ChatChannelListCollectionViewCell<ExtraData>.self

        /// A button used for creating new channels.
        public var newChannelButton: UIButton.Type = _ChatChannelCreateNewButton<ExtraData>.self

        /// The logic to generate a name for the given channel.
        public var channelNamer: ChatChannelNamer.Type = ChatChannelNamer.self

        /// The subviews that make the list item view.
        public var channelListItemSubviews = ChannelListItemSubviews()
    }
    
    struct ChannelListItemSubviews {
        /// A view that shows a user avatar including an indicator of the user presence (online/offline).
        public var avatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self
        /// A type for the view that shows a number of unread messages in channel.
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
