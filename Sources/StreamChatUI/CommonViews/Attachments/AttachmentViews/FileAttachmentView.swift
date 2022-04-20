//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the file attachment.
open class FileAttachmentView: _View, AppearanceProvider {
    open var height: CGFloat = 54
    
    public struct Content {
        /// The title of the attachment.
        var title: String
        /// The size of the attachment.
        var size: Int64
        /// The attachment type.
        var iconName: String?
        
        public init(title: String, size: Int64, iconName: String?) {
            self.title = title
            self.size = size
            self.iconName = iconName
        }
    }
    
    public var content: Content? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    public private(set) lazy var fileNameLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    public private(set) lazy var fileSizeLabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory
    
    public private(set) lazy var fileNameAndSizeStack: ContainerStackView = {
        let stack = ContainerStackView(arrangedSubviews: [fileNameLabel, fileSizeLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 3
        return stack
            .withoutAutoresizingMaskConstraints
            .withAccessibilityIdentifier(identifier: "fileNameAndSizeStack")
    }()

    /// The image view that displays the file icon of the attachment.
    public private(set) lazy var fileIconImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()
        
        backgroundColor = appearance.colorPalette.background
        layer.cornerRadius = 15
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.borderColor = appearance.colorPalette.border.cgColor

        fileIconImageView.contentMode = .center

        fileSizeLabel.textColor = appearance.colorPalette.subtitleText
        fileSizeLabel.font = appearance.fonts.subheadlineBold

        fileNameLabel.textColor = appearance.colorPalette.text
        fileNameLabel.font = appearance.fonts.bodyBold
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
    }

    override open func setUpLayout() {
        super.setUpLayout()
        
        addSubview(fileIconImageView)
        addSubview(fileNameAndSizeStack)

        NSLayoutConstraint.activate([
            heightAnchor.pin(equalToConstant: height),
            
            fileIconImageView.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
            fileIconImageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
            fileIconImageView.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor),
            
            fileNameAndSizeStack.leadingAnchor.pin(
                equalToSystemSpacingAfter: fileIconImageView.trailingAnchor,
                multiplier: 2
            ),
            fileNameAndSizeStack.centerYAnchor.pin(equalTo: centerYAnchor),
            fileNameAndSizeStack.topAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
            fileNameAndSizeStack.bottomAnchor.pin(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor),
            // This is to avoid the file name to go under the "X" Close button, which doesn't belong to this view.
            fileNameAndSizeStack.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor, constant: -30)
        ])
    }
    
    override open func updateContent() {
        super.updateContent()
        
        guard let content = content else { return }
        let icon = content.iconName.flatMap { appearance.images.documentPreviews[$0] }
            ?? appearance.images.fileFallback
        fileNameLabel.text = content.title
        fileIconImageView.image = icon
        fileSizeLabel.text = AttachmentFile.sizeFormatter.string(fromByteCount: content.size)
    }
}
