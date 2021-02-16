//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol _BaseChatMessageCollectionViewCellDelegate: AnyObject {
    associatedtype ExtraData: ExtraDataTypes
    
    func chatMessageCollectionViewCell(
        _ cell: _BaseChatMessageCollectionViewCell<ExtraData>,
        didTapThread message: _ChatMessageGroupPart<ExtraData>?
    )
    func chatMessageCollectionViewCell(
        _ cell: _BaseChatMessageCollectionViewCell<ExtraData>,
        didTapErrorIndicator message: _ChatMessageGroupPart<ExtraData>?
    )
    func chatMessageCollectionViewCell(
        _ cell: _BaseChatMessageCollectionViewCell<ExtraData>,
        didTapLink attachment: ChatMessageDefaultAttachment?
    )
}

public typealias BaseСhatMessageCollectionViewCell = _BaseChatMessageCollectionViewCell<NoExtraData>

open class _BaseChatMessageCollectionViewCell<ExtraData: ExtraDataTypes>: CollectionViewCell, UIConfigProvider {
    public struct Delegate {
        public var onThreadTap: (_BaseChatMessageCollectionViewCell, _ChatMessageGroupPart<ExtraData>?) -> Void
        public var onErrorIndicatorTap: (_BaseChatMessageCollectionViewCell, _ChatMessageGroupPart<ExtraData>?) -> Void
        public var onLinkTap: (_BaseChatMessageCollectionViewCell, ChatMessageDefaultAttachment?) -> Void
        
        static func wrap<T: _BaseChatMessageCollectionViewCellDelegate>(_ delegate: T)
            -> _BaseChatMessageCollectionViewCell.Delegate where T.ExtraData == ExtraData {
            _BaseChatMessageCollectionViewCell.Delegate(
                onThreadTap: { [weak delegate] in
                    delegate?.chatMessageCollectionViewCell($0, didTapThread: $1)
                },
                onErrorIndicatorTap: { [weak delegate] in
                    delegate?.chatMessageCollectionViewCell($0, didTapErrorIndicator: $1)
                },
                onLinkTap: { [weak delegate] in
                    delegate?.chatMessageCollectionViewCell($0, didTapLink: $1)
                }
            )
        }
    }
    
    class var reuseId: String { String(describing: self) }
    
    public var delegate: Delegate? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }
    
    private(set) var hasCompletedStreamSetup = false
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard superview != nil, !hasCompletedStreamSetup else { return }
        hasCompletedStreamSetup = true
    }
    
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

public typealias СhatMessageCollectionViewCell = _СhatMessageCollectionViewCell<NoExtraData>

open class _СhatMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _BaseChatMessageCollectionViewCell<ExtraData> {
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
        
        messageView.onThreadTap = { [unowned self] in delegate?.onThreadTap(self, $0) }
        messageView.onLinkTap = { [unowned self] in delegate?.onLinkTap(self, $0) }
        messageView.onErrorIndicatorTap = { [unowned self] in delegate?.onErrorIndicatorTap(self, $0) }
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

public typealias СhatMessageAttachmentCollectionViewCell = _СhatMessageAttachmentCollectionViewCell<NoExtraData>

open class _СhatMessageAttachmentCollectionViewCell<ExtraData: ExtraDataTypes>: _BaseChatMessageCollectionViewCell<ExtraData> {
    // MARK: - Subviews
    
    public private(set) lazy var messageView = uiConfig
        .messageList
        .messageAttachmentContentView
        .init()
        .withoutAutoresizingMaskConstraints
    
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
        
        messageView.onThreadTap = { [unowned self] in delegate?.onThreadTap(self, $0) }
        messageView.onLinkTap = { [unowned self] in delegate?.onLinkTap(self, $0) }
        messageView.onErrorIndicatorTap = { [unowned self] in delegate?.onErrorIndicatorTap(self, $0) }
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
