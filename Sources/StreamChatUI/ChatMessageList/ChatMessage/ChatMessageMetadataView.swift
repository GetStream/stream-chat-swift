//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageMetadataView = _ChatMessageMetadataView<NoExtraData>

open class _ChatMessageMetadataView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    public struct Content {
        public let message: _ChatMessage<ExtraData>
        public let isAuthorNameShown: Bool
    }

    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    /// The date formatter of the `timestampLabel`
    public lazy var dateFormatter: DateFormatter = .makeDefault()
    
    // MARK: - Subviews

    public private(set) lazy var stack = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var eyeContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var timestampLabel = UILabel()
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var authorLabel = UILabel()
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var eyeImageView = UIImageView()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var eyeTextLabel = UILabel()
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override open func setUp() {
        super.setUp()

        eyeImageView.contentMode = .scaleAspectFit
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        let color = uiConfig.colorPalette.subtitleText

        eyeTextLabel.textColor = color
        eyeTextLabel.font = uiConfig.font.footnote
        eyeTextLabel.text = L10n.Message.onlyVisibleToYou

        eyeImageView.tintColor = color
        eyeImageView.image = uiConfig.images.onlyVisibleToCurrentUser

        timestampLabel.font = uiConfig.font.footnote
        timestampLabel.adjustsFontForContentSizeCategory = true
        timestampLabel.textColor = color
    }

    override open func setUpLayout() {
        super.setUpLayout()

        eyeContainer.addArrangedSubview(eyeImageView)
        eyeContainer.addArrangedSubview(eyeTextLabel)

        stack.addArrangedSubview(eyeContainer)
        stack.addArrangedSubview(authorLabel)
        stack.addArrangedSubview(timestampLabel)

        embed(stack)
    }

    override open func updateContent() {
        super.updateContent()

        if let createdAt = content?.message.createdAt {
            timestampLabel.text = dateFormatter.string(from: createdAt)
        } else {
            timestampLabel.text = nil
        }

        eyeContainer.isVisible = content?.message.onlyVisibleForCurrentUser ?? false

        authorLabel.isVisible = content?.isAuthorNameShown ?? false
        authorLabel.text = content?.message.author.name
    }
}

private extension _ChatMessage {
    var onlyVisibleForCurrentUser: Bool {
        guard isSentByCurrentUser else {
            return false
        }

        return deletedAt != nil || type == .ephemeral
    }
}
