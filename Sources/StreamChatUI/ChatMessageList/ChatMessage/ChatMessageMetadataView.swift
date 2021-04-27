//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageMetadataView = _ChatMessageMetadataView<NoExtraData>

open class _ChatMessageMetadataView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    /// The date formatter of the `timestampLabel`
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    
    // MARK: - Subviews

    public private(set) lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = UIStackView.spacingUseSystem
        return stack.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var currentUserVisabilityIndicator = components
        .messageList
        .messageContentSubviews
        .onlyVisibleForCurrentUserIndicator
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var timestampLabel: UILabel = UILabel().withBidirectionalLanguagesSupport
    
    // MARK: - Overrides

    override open func setUpAppearance() {
        super.setUpAppearance()
        let color = appearance.colorPalette.subtitleText
        currentUserVisabilityIndicator.textLabel.textColor = color
        currentUserVisabilityIndicator.imageView.tintColor = color
        
        timestampLabel.font = appearance.fonts.subheadline
        timestampLabel.adjustsFontForContentSizeCategory = true
        timestampLabel.textColor = color
    }

    override open func setUpLayout() {
        stack.addArrangedSubview(currentUserVisabilityIndicator)
        stack.addArrangedSubview(timestampLabel)
        embed(stack)
    }

    override open func updateContent() {
        if let createdAt = message?.createdAt {
            timestampLabel.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel.text = nil
        }
        currentUserVisabilityIndicator.isVisible = message?.onlyVisibleForCurrentUser ?? false
    }
}

open class ChatMessageOnlyVisibleForCurrentUserIndicator: _View, AppearanceProvider {
    // MARK: - Subviews

    public private(set) lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = UIStackView.spacingUseSystem
        return stack.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.fonts.subheadline
        label.adjustsFontForContentSizeCategory = true
        return label.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override open func setUpAppearance() {
        super.setUpAppearance()
        imageView.image = appearance.images.onlyVisibleToCurrentUser
        textLabel.text = L10n.Message.onlyVisibleToYou
    }

    override open func setUpLayout() {
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(textLabel)
        embed(stack)

        imageView.widthAnchor.pin(equalTo: imageView.heightAnchor).isActive = true
    }
}
