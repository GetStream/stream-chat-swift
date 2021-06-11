//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public typealias AttachmentViewCatalog = _AttachmentViewCatalog<NoExtraData>

open class _AttachmentViewCatalog<ExtraData: ExtraDataTypes> {
    open class func attachmentViewInjectorClassFor(
        message: _ChatMessage<ExtraData>,
        components: _Components<ExtraData>
    ) -> _AttachmentViewInjector<ExtraData>.Type? {
        let attachmentCounts = message.attachmentCounts

        if attachmentCounts.keys.contains(.image) {
            return components.galleryAttachmentInjector
        } else if attachmentCounts.keys.contains(.giphy) {
            return components.giphyAttachmentInjector
        } else if attachmentCounts.keys.contains(.file) {
            return components.filesAttachmentInjector
        } else if attachmentCounts.keys.contains(.linkPreview) {
            return components.linkAttachmentInjector
        } else {
            return nil
        }
    }
}
