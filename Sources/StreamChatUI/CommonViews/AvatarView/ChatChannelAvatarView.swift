//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a channel avatar including an online indicator if any user is online.
public typealias ChatChannelAvatarView = _ChatChannelAvatarView<NoExtraData>

/// A view that shows a channel avatar including an online indicator if any user is online.
open class _ChatChannelAvatarView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider, SwiftUIRepresentable {
    /// A view that shows the avatar image
    open private(set) lazy var presenceAvatarView: _ChatPresenceAvatarView<ExtraData> = uiConfig
        .presenceAvatarView.init()
        .withoutAutoresizingMaskConstraints

    /// The data this view component shows.
    open var content: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) {
        didSet { updateContentIfNeeded() }
    }

    override open func setUpLayout() {
        super.setUpLayout()
        embed(presenceAvatarView)
    }

    override open func updateContent() {
        guard let channel = content.channel else {
            presenceAvatarView.avatarView.imageView.loadImage(from: nil)
            return
        }

        let (avatarURL, isOnlineIndicatorVisible): (URL?, Bool) = {
            // Try to get the explicit channel avatar first
            if let avatarURL = channel.imageURL {
                return (avatarURL, false)
            }

            // TODO: https://stream-io.atlassian.net/browse/CIS-652
            // this is just placeholder implementation:

            let firstOtherMember = channel.cachedMembers
                .sorted { $0.memberCreatedAt < $1.memberCreatedAt }
                .first(where: { $0.id != content.currentUserId })

            return (firstOtherMember?.imageURL, firstOtherMember?.isOnline ?? false)
        }()

        presenceAvatarView.avatarView.imageView.loadImage(from: avatarURL)
        presenceAvatarView.onlineIndicatorView.isVisible = isOnlineIndicatorVisible
    }
}
