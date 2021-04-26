//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageMetadataView = _ChatMessageMetadataView<NoExtraData>

open class _ChatMessageMetadataView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
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

    public private(set) lazy var currentUserVisabilityIndicator = uiConfig
        .messageList
        .messageContentSubviews
        .onlyVisibleForCurrentUserIndicator
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var timestampLabel: UILabel = UILabel().withBidirectionalLanguagesSupport
    
    // MARK: - Overrides

    override open func setUpAppearance() {
        super.setUpAppearance()
        let color = uiConfig.colorPalette.subtitleText
        currentUserVisabilityIndicator.textLabel.textColor = color
        currentUserVisabilityIndicator.imageView.tintColor = color
        
        timestampLabel.font = uiConfig.font.subheadline
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

open class ChatMessageOnlyVisibleForCurrentUserIndicator<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
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
        label.font = uiConfig.font.subheadline
        label.adjustsFontForContentSizeCategory = true
        return label.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override open func setUpAppearance() {
        super.setUpAppearance()
        imageView.image = uiConfig.images.onlyVisibleToCurrentUser
        textLabel.text = L10n.Message.onlyVisibleToYou
    }

    override open func setUpLayout() {
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(textLabel)
        embed(stack)

        imageView.widthAnchor.pin(equalTo: imageView.heightAnchor).isActive = true
    }
}
