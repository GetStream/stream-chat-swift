//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelAvatarView<ExtraData: UIExtraDataTypes>: AvatarView {
    // MARK: - Properties

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
    }
    
    // MARK: - Public
    
    open func updateContent() {
        guard let channel = channelAndUserId.channel else {
            imageView.image = nil
            return
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
