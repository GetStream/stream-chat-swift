//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public class MessageCell<ExtraData: ExtraDataTypes>: _CollectionViewCell, UIConfigProvider {
    static var reuseId: String { "message_cell" }

    class var messageContentViewClass: _MessageContentView<ExtraData>.Type {
        _MessageContentView<ExtraData>.self
    }

    let messageContentView = messageContentViewClass
        .init()
        .withoutAutoresizingMaskConstraints

    override public func setUpLayout() {
        super.setUpLayout()

        contentView.embed(messageContentView)
    }

    override public func prepareForReuse() {
        super.prepareForReuse()

        messageContentView.delegate = nil
        messageContentView.content = nil
    }

    override open func preferredLayoutAttributesFitting(
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
