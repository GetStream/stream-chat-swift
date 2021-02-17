//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that shows a user avatar including an indicator of the user presence (online/offline).
public typealias ChatChannelAvatarView = _ChatChannelAvatarView<NoExtraData>

/// A view that shows a user avatar including an indicator of the user presence (online/offline).
open class _ChatChannelAvatarView<ExtraData: ExtraDataTypes>: ChatAvatarView, UIConfigProvider {
    public enum AvatarViewContent {
        case user(user: _ChatUser<ExtraData.User>?)
        case channelAndUserId(channel: _ChatChannel<ExtraData>?, currentUserId: UserId?)
    }
    
    /// A view indicating whether the user this view represents is online.
    open private(set) lazy var onlineIndicatorView: UIView = uiConfig
        .channelList
        .channelListItemSubviews
        .onlineIndicator.init()
        .withoutAutoresizingMaskConstraints

    /// The data this view component shows.
    open var content: AvatarViewContent? {
        didSet { updateContentIfNeeded() }
    }

    override public func defaultAppearance() {
        super.defaultAppearance()
        onlineIndicatorView.isHidden = true
    }

    override open func setUpLayout() {
        super.setUpLayout()
        // Add online indicator view
        addSubview(onlineIndicatorView)
        onlineIndicatorView.pin(anchors: [.top, .right], to: self)
        onlineIndicatorView.widthAnchor
            .pin(equalTo: widthAnchor, multiplier: 0.3)
            .isActive = true
    }
    
    override open func updateContent() {
        guard let content = content else { return }

        switch content {
        case let .channelAndUserId(channel, currentUserId):
            guard let channel = channel else {
                imageView.loadImage(from: nil)
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
                    .first(where: { $0.id != currentUserId })

                return (firstOtherMember?.imageURL, firstOtherMember?.isOnline ?? false)
            }()

            imageView.loadImage(from: avatarURL)
            onlineIndicatorView.isVisible = isOnlineIndicatorVisible

        case let .user(user):
            if let url = user?.imageURL {
                imageView.loadImage(from: url)
            } else {
                imageView.image = uiConfig.images.userAvatarPlaceholder1
            }
            onlineIndicatorView.isVisible = user?.isOnline ?? false
        }
    }
}
