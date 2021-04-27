//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UICollectionViewLayout

public extension _Components {
    struct ChannelList {
        /// A button used for creating new channels.
        public var newChannelButton: UIButton.Type = ChatChannelCreateNewButton.self

        /// The logic to generate a name for the given channel.
        public var channelNamer: ChatChannelNamer<ExtraData> = DefaultChatChannelNamer()

        /// The collection view of the Channel List.
        public var collectionView: UICollectionView.Type = UICollectionView.self

        /// The collection view layout of the Channel List.
        public var collectionLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self

        /// A `UICollectionViewCell` subclass that shows channel information.
        public var collectionViewCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
            _ChatChannelListCollectionViewCell<ExtraData>.self

        /// The Cell Separator View.
        public var cellSeparatorReusableView: UICollectionReusableView.Type = CellSeparatorReusableView.self

        /// `SwibeableView` instance wrapped in the cell to support action views on swipe in the cell.
        public var swipeableView: _SwipeableView<ExtraData>.Type =
            _SwipeableView<ExtraData>.self

        /// The `UIStackView` that arranges buttons revealed by swipe gesture.
        public var swipeableViewStackView: UIStackView.Type = UIStackView.self

        /// A `ChatChannelListItemView` subclass view that shows channel information.
        public var itemView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self

        /// The subviews that compose the `itemView`.
        public var itemSubviews = ItemSubviews()

        /// The subviews of that compose the `itemView`.
        public struct ItemSubviews {
            /// A label that shows a title of channel. This should be result of `ChatChannelNamer`.
            public var titleLabel: UILabel.Type = UILabel.self

            /// A label that shows a subtitle of channel, typically shows if users are typing or last message,
            /// see `typingMemberOrLastMessageString` in `ChatChannelListItemView`.
            public var subtitleLabel: UILabel.Type = UILabel.self

            /// A label that shows last time of message sent.
            public var timestampLabel: UILabel.Type = UILabel.self

            /// A view that shows a user avatar including an indicator of the user presence (online/offline).
            public var avatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self

            /// A view that shows a number of unread messages in channel.
            public var unreadCountView: ChatChannelUnreadCountView.Type = ChatChannelUnreadCountView.self

            /// A view that shows a read/unread status of the last message in channel.
            public var readStatusView: ChatChannelReadStatusCheckmarkView.Type =
                ChatChannelReadStatusCheckmarkView.self
        }
    }
}
