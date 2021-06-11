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

        // TODO: loop over attachments and set it to true if any attachment has title_link != ""
        let containsLink = true
        
        message.imageAttachments
        
        attachmentCounts.keys.contains(.image) || attachmentCounts.keys.contains(.media) || containsLink
        
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
