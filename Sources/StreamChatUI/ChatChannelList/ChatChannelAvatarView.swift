//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatChannelAvatarView = _ChatChannelAvatarView<NoExtraData>

open class _ChatChannelAvatarView<ExtraData: ExtraDataTypes>: СhatAvatarView, UIConfigProvider {
    // MARK: - Properties

    public private(set) lazy var onlineIndicatorView = uiConfig
        .channelList
        .channelListItemSubviews
        .onlineIndicator.init()
        .withoutAutoresizingMaskConstraints

    public var channelAndUserId: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) {
        didSet { updateContent() }
    }

    // MARK: - Overrides
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        widthAnchor.pin(equalTo: heightAnchor, multiplier: 1).isActive = true
        
        embed(imageView)
        addSubview(onlineIndicatorView)
        onlineIndicatorView.pin(anchors: [.top, .right], to: self)
        onlineIndicatorView.widthAnchor.pin(equalTo: widthAnchor, multiplier: 0.3).isActive = true
    }
    
    // MARK: - Public
    
    override open func updateContent() {
        guard let channel = channelAndUserId.channel else {
            imageView.image = nil
            return
        }

        if channel.isDirectMessageChannel,
            let currentUserId = channelAndUserId.currentUserId,
            let otherMember = channel.cachedMembers.first(where: { $0.id == currentUserId }),
            otherMember.isOnline {
            onlineIndicatorView.isHidden = false
        } else {
            onlineIndicatorView.isHidden = true
        }

        if let imageURL = channel.imageURL {
            imageView.setImage(from: imageURL)
        } else {
            imageView.image = ["pattern1", "pattern2", "pattern3", "pattern4", "pattern5"]
                .compactMap { UIImage(named: $0, in: .streamChatUI) }
                .randomElement()
        }
    }
}
