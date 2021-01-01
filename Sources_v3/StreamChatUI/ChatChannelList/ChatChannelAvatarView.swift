//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelAvatarView<ExtraData: ExtraDataTypes>: AvatarView {
    // MARK: - Properties

    public lazy var onlineIndicatorView = OnlineIndicatorView<ExtraData>().withoutAutoresizingMaskConstraints

    public var channelAndUserId: (channel: _ChatChannel<ExtraData>?, currentUserId: UserId?) {
        didSet { updateContent() }
    }
    
    override open var intrinsicContentSize: CGSize {
        .init(width: 56, height: 56)
    }
    
    // MARK: - Overrides
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
        embed(imageView)
        addSubview(onlineIndicatorView)
        onlineIndicatorView.pin(anchors: [.top, .right], to: self)
        onlineIndicatorView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.25).isActive = true
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
