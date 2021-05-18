//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatDocumentAttachmentView = _ChatDocumentAttachmentView<NoExtraData>

open class _ChatDocumentAttachmentView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    // MARK: - Properties
    
    public var discardButtonHandler: (() -> Void)?
    
    // MARK: - Subviews

    public private(set) lazy var fileNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    public private(set) lazy var fileSizeLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    public private(set) lazy var actionIconImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var fileNameAndSizeStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [fileNameLabel, fileSizeLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        return stack.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var fileIconImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    // MARK: - Overrides
    
    override open func setUp() {
        super.setUp()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(discard))
        addGestureRecognizer(tapRecognizer)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.background
        layer.cornerRadius = 16
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = appearance.colorPalette.border.cgColor

        fileIconImageView.contentMode = .center

        fileSizeLabel.textColor = appearance.colorPalette.subtitleText
        fileSizeLabel.font = appearance.fonts.subheadlineBold

        fileNameLabel.textColor = appearance.colorPalette.text
        fileNameLabel.font = appearance.fonts.bodyBold
        
        actionIconImageView.image = appearance.images.discardAttachment
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
    
    @objc func discard() {
        discardButtonHandler?()
    }
}
