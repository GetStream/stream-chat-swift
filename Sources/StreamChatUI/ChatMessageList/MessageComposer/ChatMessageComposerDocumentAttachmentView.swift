//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageComposerDocumentAttachmentView = _ChatMessageComposerDocumentAttachmentView<NoExtraData>

internal class _ChatMessageComposerDocumentAttachmentView<ExtraData: ExtraDataTypes>: _ChatMessageAttachmentInfoView<ExtraData> {
    // MARK: - Properties
    
    internal var discardButtonHandler: (() -> Void)?
    
    // MARK: - Subviews

    internal private(set) lazy var fileIconImageView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        return imageView
    }()

    // MARK: - Overrides
    
    override internal func setUp() {
        super.setUp()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(discard))
        addGestureRecognizer(tapRecognizer)
    }

    override internal func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.background
        layer.cornerRadius = 15
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = uiConfig.colorPalette.border.cgColor
        
        fileSizeLabel.textColor = uiConfig.colorPalette.subtitleText
        fileNameLabel.textColor = uiConfig.colorPalette.text
        
        actionIconImageView.image = uiConfig.images.messageComposerDiscardAttachment
    }

    override internal func setUpLayout() {
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
    
    override internal func updateContent() {
        loadingIndicator.isVisible = false
    }
    
    @objc func discard() {
        discardButtonHandler?()
    }
}
