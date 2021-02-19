//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit.UICollectionViewLayout

public extension _UIConfig {
    struct ChannelList {
        /// A button used for creating new channels.
        internal var newChannelButton: UIButton.Type = _ChatChannelCreateNewButton<ExtraData>.self

        /// The logic to generate a name for the given channel.
        internal var channelNamer: ChatChannelNamer<ExtraData> = DefaultChatChannelNamer()

        /// The collection view of the Channel List.
        internal var collectionView: UICollectionView.Type = UICollectionView.self

        /// The collection view layout of the Channel List.
        internal var collectionLayout: UICollectionViewLayout.Type = ListCollectionViewLayout.self

        /// A `UICollectionViewCell` subclass that shows channel information.
        internal var collectionViewCell: _ChatChannelListCollectionViewCell<ExtraData>.Type =
            _ChatChannelListCollectionViewCell<ExtraData>.self

        /// The Cell Separator View.
        internal var cellSeparatorReusableView: UICollectionReusableView.Type = _CellSeparatorReusableView<ExtraData>.self

        /// `SwibeableView` instance wrapped in the cell to support action views on swipe in the cell.
        internal var swipeableView: _SwipeableView<ExtraData>.Type =
            _SwipeableView<ExtraData>.self

        /// The `UIStackView` that arranges buttons revealed by swipe gesture.
        internal var swipeableViewStackView: UIStackView.Type = UIStackView.self

        /// A `ChatChannelListItemView` subclass view that shows channel information.
        internal var itemView: _ChatChannelListItemView<ExtraData>.Type = _ChatChannelListItemView<ExtraData>.self

        /// The subviews that compose the `itemView`.
        internal var itemSubviews = ItemSubviews()

        /// The subviews of that compose the `itemView`.
        public struct ItemSubviews {
            /// A label that shows a title of channel. This should be result of `ChatChannelNamer`.
            internal var titleLabel: UILabel.Type = UILabel.self

            /// A label that shows a subtitle of channel, typically shows if users are typing or last message,
            /// see `typingMemberOrLastMessageString` in `ChatChannelListItemView`.
            internal var subtitleLabel: UILabel.Type = UILabel.self

            /// A label that shows last time of message sent.
            internal var timestampLabel: UILabel.Type = UILabel.self

            /// A view that shows a user avatar including an indicator of the user presence (online/offline).
            internal var avatarView: _ChatChannelAvatarView<ExtraData>.Type = _ChatChannelAvatarView.self

            /// A view that shows a number of unread messages in channel.
            internal var unreadCountView: _ChatChannelUnreadCountView<ExtraData>.Type = _ChatChannelUnreadCountView<ExtraData>.self

            /// A view that shows a read/unread status of the last message in channel.
            internal var readStatusView: _ChatChannelReadStatusCheckmarkView<ExtraData>.Type =
                _ChatChannelReadStatusCheckmarkView<ExtraData>.self
        }
    }
}
