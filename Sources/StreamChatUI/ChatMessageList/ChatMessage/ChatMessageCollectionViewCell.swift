//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The cell that displays the message content of a dynamic type and layout.
/// Once the cell is set up it is expected to be dequeued for messages with
/// the same content and layout the cell has already been configured with.
public typealias ChatMessageCollectionViewCell = _ChatMessageCollectionViewCell<NoExtraData>

/// The cell that displays the message content of a dynamic type and layout.
/// Once the cell is set up it is expected to be dequeued for messages with
/// the same content and layout the cell has already been configured with.
public final class _ChatMessageCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell {
    public static var reuseId: String { "\(self)" }

    public private(set) var messageContentView: _ChatMessageContentView<ExtraData>?

    override public func prepareForReuse() {
        super.prepareForReuse()

        messageContentView?.prepareForReuse()
    }

    public func setMessageContentIfNeeded(
        contentViewClass: _ChatMessageContentView<ExtraData>.Type,
        attachmentViewInjectorType: _AttachmentViewInjector<ExtraData>.Type?,
        options: ChatMessageLayoutOptions
    ) {
        guard messageContentView == nil else {
            log.assert(type(of: messageContentView!) == contentViewClass, """
            Attempt to setup different content class: ("\(contentViewClass)").
            `СhatMessageCollectionViewCell` is supposed to be configured only once.
            """)
            return
        }

        messageContentView = contentViewClass.init().withoutAutoresizingMaskConstraints
        // We add the content view to the view hierarchy before invoking `setUpLayoutIfNeeded`
        // (where the subviews are instantiated and configured) to use `components` and `appearance`
        // taken from the responder chain.
        contentView.addSubview(messageContentView!)
        
        messageContentView?.pin(anchors: [.leading, .top, .trailing], to: contentView)
        
        // Bottom anchor is pinned with a lower priority to make the content view stick to the top of the
        // cell during animations.
        messageContentView?.bottomAnchor
            .pin(lessThanOrEqualTo: contentView.bottomAnchor)
            .with(priority: .streamAlmostRequire)
            .isActive = true
        
        messageContentView!.setUpLayoutIfNeeded(options: options, attachmentViewInjectorType: attachmentViewInjectorType)
    }

    override public func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
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
