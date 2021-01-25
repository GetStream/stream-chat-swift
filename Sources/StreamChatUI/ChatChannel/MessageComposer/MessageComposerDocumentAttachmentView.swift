//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerDocumentAttachmentView<ExtraData: ExtraDataTypes>: _ChatMessageAttachmentInfoView<ExtraData> {
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

    override public func defaultAppearance() {
        backgroundColor = uiConfig.colorPalette.generalBackground
        layer.cornerRadius = 15
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = uiConfig.colorPalette.incomingMessageBubbleBorder.cgColor
        
        fileSizeLabel.textColor = uiConfig.colorPalette.subtitleText
        fileNameLabel.textColor = uiConfig.colorPalette.text
        
        actionIconImageView.image = UIImage(named: "discardAttachment", in: .streamChatUI)
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
