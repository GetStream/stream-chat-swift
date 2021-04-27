//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageComposerDocumentAttachmentView = _ChatMessageComposerDocumentAttachmentView<NoExtraData>

open class _ChatMessageComposerDocumentAttachmentView<ExtraData: ExtraDataTypes>: _ChatMessageAttachmentInfoView<ExtraData> {
    // MARK: - Properties
    
    public var discardButtonHandler: (() -> Void)?
    
    // MARK: - Subviews

    public private(set) lazy var fileIconImageView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        return imageView
    }()

    // MARK: - Overrides
    
    override open func setUp() {
        super.setUp()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(discard))
        addGestureRecognizer(tapRecognizer)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.background
        layer.cornerRadius = 15
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = appearance.colorPalette.border.cgColor
        
        fileSizeLabel.textColor = appearance.colorPalette.subtitleText
        fileNameLabel.textColor = appearance.colorPalette.text
        
        actionIconImageView.image = appearance.images.messageComposerDiscardAttachment
    }

    override open func setUpLayout() {
        addSubview(fileIconImageView)
        addSubview(actionIconImageView)
        addSubview(fileNameAndSizeStack)

        NSLayoutConstraint.activate([
            fileIconImageView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            fileIconImageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            fileIconImageView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor),
            
            actionIconImageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            actionIconImageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
            actionIconImageView.leadingAnchor.pin(
                equalToSystemSpacingAfter: fileNameAndSizeStack.trailingAnchor,
                multiplier: 1
            ),
            
            fileNameAndSizeStack.leadingAnchor.pin(
                equalToSystemSpacingAfter: fileIconImageView.trailingAnchor,
                multiplier: 2
            ),
            fileNameAndSizeStack.centerYAnchor.pin(equalTo: centerYAnchor),
            fileNameAndSizeStack.topAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
            fileNameAndSizeStack.bottomAnchor.pin(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor)
        ])
    }
    
    override open func updateContent() {
        loadingIndicator.isVisible = false
    }
    
    @objc func discard() {
        discardButtonHandler?()
    }
}
