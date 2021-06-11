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

    var topConstraint: NSLayoutConstraint?

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
        
        messageContentView?.pin(anchors: [.leading, .bottom, .trailing], to: contentView)

        topConstraint = messageContentView?.topAnchor.pin(equalTo: contentView.topAnchor)
        topConstraint?.isActive = true

        // Bottom anchor is pinned with a lower priority to make the content view stick to the top of the
        // cell during animations.
//        messageContentView?.bottomAnchor
//            .pin(lessThanOrEqualTo: contentView.bottomAnchor)
//            .with(priority: .streamAlmostRequire)
//            .isActive = true
        
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
        
        (preferredAttributes as? MessageCellLayoutAttributes)?.layoutOptions = messageContentView?.layoutOptions

        let layoutAttributes = preferredAttributes as! MessageCellLayoutAttributes

        print(
            "\npreferredLayoutAttributesFitting: \(address(o: self)) | \((preferredAttributes as? MessageCellLayoutAttributes)!.tag) "
        )
        print("""
            - now: \(layoutAttributes.layoutOptions)
            - prev: \(layoutAttributes.previousLayoutOptions)
        """)

        layoutAttributes.tag += "_adjusted"

        return preferredAttributes
    }

    override public func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        messageContentView?.isHidden = layoutAttributes.isHidden

        guard let layoutAttributes = layoutAttributes as? MessageCellLayoutAttributes else {
            print()
            return
        }

        print("""

        > apply attributes \(address(o: self)) | tag: \(layoutAttributes.tag):
            - now: \(layoutAttributes.layoutOptions)
            - prev: \(layoutAttributes.previousLayoutOptions)
        """)

        if layoutAttributes.previousLayoutOptions?.contains(.reactions) == false
            && messageContentView?.layoutOptions.contains(.reactions) == true
        {
//            window?.layer.speed = 0.1

            let reactionBubbleHeight = messageContentView?.reactionsBubbleView?.heightAnchor.constraint(equalToConstant: 0)
            let reactionBubbleWidth = messageContentView?.reactionsBubbleView?.widthAnchor.constraint(equalToConstant: 0)
            let reactionHeight = messageContentView?.reactionsView?.heightAnchor.constraint(equalToConstant: 0)

            UIView.performWithoutAnimation {
//                reactionBubbleHeight?.isActive = true
//                reactionHeight?.isActive = true
//                reactionBubbleWidth?.isActive = true

                topConstraint?.isActive = false

                messageContentView?.reactionsBubbleView?.transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
                    .concatenating(.init(translationX: 10, y: frame.height / 2.0))
                    .concatenating(.init(rotationAngle: -3.14 / 4.0))

                messageContentView?.reactionsBubbleView?.alpha = 0

                contentView.layoutIfNeeded()
            }

//            reactionBubbleHeight?.isActive = false
//            reactionHeight?.isActive = false
//            reactionBubbleWidth?.isActive = false

            topConstraint?.isActive = true

            UIView.animate(
                withDuration: 1,
                delay: 0,
                usingSpringWithDamping: 0.5,
                initialSpringVelocity: 10,
                options: [],
                animations: {
                    self.messageContentView?.reactionsBubbleView?.transform = .identity
                    self.messageContentView?.reactionsBubbleView?.alpha = 1

                    self.messageContentView?.reactionsBubbleView?.layoutIfNeeded()

                },
                completion: nil
            )
//            }

//            self.messageContentView?.layoutIfNeeded()
        }
    }
}

func address<T: AnyObject>(o: T) -> Int {
    unsafeBitCast(o, to: Int.self)
}
