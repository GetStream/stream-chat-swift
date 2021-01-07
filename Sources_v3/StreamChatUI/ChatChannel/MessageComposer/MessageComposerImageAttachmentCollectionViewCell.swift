//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerImageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>: CollectionViewCell,
    UIConfigProvider {
    // MARK: - Properties
    
    class var reuseId: String { String(describing: self) }
    
    public var discardButtonHandler: (() -> Void)?
    
    // MARK: - Subviews
    
    public private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var discardButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints
        
    // MARK: - Lifecycle
    
    override open func setUp() {
        super.setUp()
        
        discardButton.addTarget(self, action: #selector(discard), for: .touchUpInside)
    }
    
    override public func defaultAppearance() {
        discardButton.setImage(UIImage(named: "discardAttachment", in: .streamChatUI), for: .normal)
        
        layer.masksToBounds = true
        layer.cornerRadius = 15
        
        imageView.contentMode = .scaleAspectFill
    }
        
    override open func setUpLayout() {
        contentView.embed(imageView)
        
        contentView.addSubview(discardButton)
        
        NSLayoutConstraint.activate([
            discardButton.topAnchor.pin(equalTo: contentView.layoutMarginsGuide.topAnchor),
            discardButton.trailingAnchor.pin(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            discardButton.leadingAnchor.pin(
                greaterThanOrEqualToSystemSpacingAfter: contentView.layoutMarginsGuide.leadingAnchor,
                multiplier: 2
            )
        ])
    }
    
    @objc func discard() {
        discardButtonHandler?()
    }
}
