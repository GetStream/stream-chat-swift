//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UICollectionViewLayout

public extension _UIConfig {
    struct ChannelList {
        /// A button used for creating new channels.
        public var newChannelButton: UIButton.Type = _ChatChannelCreateNewButton<ExtraData>.self

        /// The logic to generate a name for the given channel.
        public var channelNamer: ChatChannelNamer<ExtraData> = DefaultChatChannelNamer()

        /// The collection view of the Channel List.
        public var collectionView: ChatChannelListCollectionView.Type = ChatChannelListCollectionView.self

        /// The collection view layout of the Channel List.
        public var collectionLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self

        /// A `UICollectionViewCell` subclass that shows channel information.
        public var collectionViewCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
            _ChatChannelListCollectionViewCell<ExtraData>.self

        /// The Cell Separator View.
        public var cellSeparatorReusableView: UICollectionReusableView.Type = _CellSeparatorReusableView<ExtraData>.self

        /// The base view of the channel list item to support swipeable gestures.
        public var swipeableItemView: _ChatChannelSwipeableListItemView<ExtraData>.Type =
            _ChatChannelSwipeableListItemView<ExtraData>.self

        /// The subviews that compose the `swipeableItemView`.
        public var swipeableItemSubviews = SwipeableItemSubviews()

        /// A `ChatChannelSwipeableListItemView` subclass view that shows channel information.
        public var itemView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self

        /// The subviews that compose the `itemView`.
        public var itemSubviews = ItemSubviews()

        /// The subviews of that compose the `itemView`.
        public struct ItemSubviews {
            /// A view that shows a user avatar including an indicator of the user presence (online/offline).
            public var avatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self

            /// A view used as an online activity indicator for avatars.
            public var avatarOnlineIndicator: UIView.Type = _ChatOnlineIndicatorView<ExtraData>.self

            /// A view that shows a number of unread messages in channel.
            public var unreadCountView: _ChatChannelUnreadCountView<ExtraData>.Type = _ChatChannelUnreadCountView<ExtraData>.self

            /// A view that shows a read/unread status of the last message in channel.
            public var readStatusView: _ChatChannelReadStatusCheckmarkView<ExtraData>.Type =
                _ChatChannelReadStatusCheckmarkView<ExtraData>.self
        }

        /// The subviews that compose the `swipeableItemView`.
        public struct SwipeableItemSubviews {
            /// The main content view which you should always use for embedding your cell content.
            public var cellContentView: UIView.Type = UIView.self

            /// The delete button.
            public var deleteButton: UIButton.Type = UIButton.self

            /// The `UIStackView` that arranges buttons revealed by swipe gesture.
            public var actionButtonStack: UIStackView.Type = UIStackView.self
        }
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
