//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

open class ChatReadStatusCheckmarkView: View, UIConfigProvider {
    public typealias ExtraData = DefaultUIExtraData

    public enum Status {
        case read, unread, empty
    }
    
    // MARK: - Properties
    
    public var status: Status = .empty {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    // MARK: - Subviews
    
    private lazy var imageView = UIImageView().withoutAutoresizingMaskConstraints
    
    // MARK: - Public

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        updateContentIfNeeded()
    }
    
    override open func setUpAppearance() {
        imageView.contentMode = .scaleAspectFit
    }
    
    override open func setUpLayout() {
        embed(imageView)
        widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
    }
    
    override open func updateContent() {
        switch status {
        case .empty:
            imageView.image = nil
        case .read:
            imageView.image = UIImage(named: "doubleCheckmark", in: .streamChatUI)
            imageView.tintColor = tintColor
        case .unread:
            imageView.image = UIImage(named: "checkmark", in: .streamChatUI)
            imageView.tintColor = uiConfig.colorPalette.unreadChatTint
        }
    }
}
