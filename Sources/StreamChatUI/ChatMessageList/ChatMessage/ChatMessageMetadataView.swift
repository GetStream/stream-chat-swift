//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageMetadataView = _ChatMessageMetadataView<NoExtraData>

internal class _ChatMessageMetadataView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    internal var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    /// The date formatter of the `timestampLabel`
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    
    // MARK: - Subviews

    internal private(set) lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = UIStackView.spacingUseSystem
        return stack.withoutAutoresizingMaskConstraints
    }()

    internal private(set) lazy var currentUserVisabilityIndicator = uiConfig
        .messageList
        .messageContentSubviews
        .onlyVisibleForCurrentUserIndicator
        .init()
        .withoutAutoresizingMaskConstraints

    internal private(set) lazy var timestampLabel: UILabel = UILabel().withBidirectionalLanguagesSupport
    
    // MARK: - Overrides

    override internal func defaultAppearance() {
        let color = uiConfig.colorPalette.subtitleText
        currentUserVisabilityIndicator.textLabel.textColor = color
        currentUserVisabilityIndicator.imageView.tintColor = color
        
        timestampLabel.font = uiConfig.fonts.subheadline
        timestampLabel.adjustsFontForContentSizeCategory = true
        timestampLabel.textColor = color
    }

    override internal func setUpLayout() {
        stack.addArrangedSubview(currentUserVisabilityIndicator)
        stack.addArrangedSubview(timestampLabel)
        embed(stack)
    }

    override internal func updateContent() {
        if let createdAt = message?.createdAt {
            timestampLabel.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel.text = nil
        }
        currentUserVisabilityIndicator.isVisible = message?.onlyVisibleForCurrentUser ?? false
    }
}

internal class ChatMessageOnlyVisibleForCurrentUserIndicator<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    // MARK: - Subviews

    internal private(set) lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = UIStackView.spacingUseSystem
        return stack.withoutAutoresizingMaskConstraints
    }()

    internal private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView.withoutAutoresizingMaskConstraints
    }()

    internal private(set) lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = uiConfig.fonts.subheadline
        label.adjustsFontForContentSizeCategory = true
        return label.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override internal func defaultAppearance() {
        imageView.image = uiConfig.images.onlyVisibleToCurrentUser
        textLabel.text = L10n.Message.onlyVisibleToYou
    }

    override internal func setUpLayout() {
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(textLabel)
        embed(stack)

        imageView.widthAnchor.pin(equalTo: imageView.heightAnchor).isActive = true
    }
}

private extension _ChatMessageGroupPart {
    var onlyVisibleForCurrentUser: Bool {
        guard message.isSentByCurrentUser else {
            return false
        }

        return message.deletedAt != nil || message.type == .ephemeral
    }
}
