//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias СhatMessageCollectionViewCell = _СhatMessageCollectionViewCell<NoExtraData>

open class _СhatMessageCollectionViewCell<ExtraData: ExtraDataTypes>: CollectionViewCell, UIConfigProvider {
    class var reuseId: String { String(describing: self) }

    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var messageView = uiConfig.messageList.messageContentView.init().withoutAutoresizingMaskConstraints
    private var hasCompletedStreamSetup = false

    // MARK: - Lifecycle

    override open func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard superview != nil, !hasCompletedStreamSetup else { return }
        hasCompletedStreamSetup = true
    }

    override open func setUpLayout() {
        contentView.addSubview(messageView)

        NSLayoutConstraint.activate([
            messageView.topAnchor.pin(equalTo: contentView.topAnchor),
            messageView.bottomAnchor.pin(equalTo: contentView.bottomAnchor),
            messageView.widthAnchor.pin(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75)
        ])
    }

    override open func updateContent() {
        messageView.message = message
    }

    // MARK: - Overrides

    override open func prepareForReuse() {
        super.prepareForReuse()

        message = nil
    }

    override open func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        guard hasCompletedStreamSetup else {
            // We cannot calculate size properly right now, because our view hierarchy is not ready yet.
            // If we just return default size, small text bubbles would not resize itself properly for no reason.
            let attributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
            attributes.frame.size.height = 300
            return attributes
        }

        let preferredAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )

        preferredAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return preferredAttributes
    }
}

class СhatIncomingMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _СhatMessageCollectionViewCell<ExtraData> {
    override func setUpLayout() {
        super.setUpLayout()
        messageView.leadingAnchor.pin(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
    }
}

class СhatOutgoingMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _СhatMessageCollectionViewCell<ExtraData> {
    override func setUpLayout() {
        super.setUpLayout()
        messageView.trailingAnchor.pin(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
}
