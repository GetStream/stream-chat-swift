//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias СhatMessageCollectionViewCell = _СhatMessageCollectionViewCell<NoExtraData>

open class _СhatMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIConfigProvider {
    class var reuseId: String { String(describing: self) }

    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var messageView = uiConfig.messageList.messageContentView.init().withoutAutoresizingMaskConstraints

    // MARK: - Lifecycle

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
        let preferredAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        
        let prototype = prototypes[Self.reuseId] as? Self ?? Self()
        prototypes[Self.reuseId] = prototype
        prototype.message = message
        prototype.streamSetup()
        preferredAttributes.frame.size = prototype.contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        return preferredAttributes
    }
}

private var prototypes = [String: UICollectionViewCell]()

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

public typealias СhatMessageAttachmentCollectionViewCell = _СhatMessageAttachmentCollectionViewCell<NoExtraData>

open class _СhatMessageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>: _СhatMessageCollectionViewCell<ExtraData> {
    private var _messageAttachmentContentView: _ChatMessageAttachmentContentView<ExtraData>?
    
    override public var messageView: _ChatMessageContentView<ExtraData> {
        if let messageContentView = _messageAttachmentContentView {
            return messageContentView
        } else {
            _messageAttachmentContentView = uiConfig
                .messageList
                .messageAttachmentContentView
                .init()
                .withoutAutoresizingMaskConstraints
            return _messageAttachmentContentView!
        }
    }
}

// swiftlint:disable:next colon
class СhatIncomingMessageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>:
    _СhatMessageAttachmentCollectionViewCell<ExtraData> {
    override func setUpLayout() {
        super.setUpLayout()
        messageView.leadingAnchor.pin(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
    }
}

// swiftlint:disable:next colon
class СhatOutgoingMessageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>:
    _СhatMessageAttachmentCollectionViewCell<ExtraData> {
    override func setUpLayout() {
        super.setUpLayout()
        messageView.trailingAnchor.pin(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
    }
}
