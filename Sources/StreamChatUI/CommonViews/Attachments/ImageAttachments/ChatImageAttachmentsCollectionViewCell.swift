//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The view cell that displays the image attachment.
public typealias ChatImageAttachmentsCollectionViewCell =
    _ChatImageAttachmentsCollectionViewCell<NoExtraData>

/// The view cell that displays the image attachment.
open class _ChatImageAttachmentsCollectionViewCell<ExtraData: ExtraDataTypes>: _CollectionViewCell,
    ComponentsProvider {
    open class var reuseId: String { String(describing: self) }

    /// A view that displays the image attachment preview.
    open private(set) lazy var imageAttachmentView = components
        .messageComposer
        .imageAttachmentCellView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpLayout() {
        super.setUpLayout()

        contentView.embed(imageAttachmentView)
    }
}
