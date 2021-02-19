//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerImageAttachmentCollectionViewCell =
    _ChatMessageComposerImageAttachmentCollectionViewCell<NoExtraData>

internal class _ChatMessageComposerImageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    UIConfigProvider {
    // MARK: - Properties
    
    class var reuseId: String { String(describing: self) }
    
    internal var discardButtonHandler: (() -> Void)?
    
    // MARK: - Subviews
    
    internal private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var discardButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints
        
    // MARK: - Lifecycle
    
    override internal func setUp() {
        super.setUp()
        
        discardButton.addTarget(self, action: #selector(discard), for: .touchUpInside)
    }
    
    override internal func defaultAppearance() {
        discardButton.setImage(uiConfig.images.messageComposerDiscardAttachment, for: .normal)
        
        layer.masksToBounds = true
        layer.cornerRadius = 15
        
        imageView.contentMode = .scaleAspectFill
    }
        
    override internal func setUpLayout() {
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
