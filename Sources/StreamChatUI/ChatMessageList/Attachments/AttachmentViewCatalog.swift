//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// A class that is used to determine the AttachmentViewInjector to use for rendering one message's attachments.
/// If your application uses custom attachment types, you will need to create a subclass and override the attachmentViewInjectorClassFor
/// method so that the correct AttachmentViewInjector is used.
open class AttachmentViewCatalog {
    open class func attachmentViewInjectorClassFor(
        message: ChatMessage,
        components: Components
    ) -> AttachmentViewInjector.Type? {
        // Do not show attachments for deleted messages
        guard !message.isDeleted else { return nil }
        
        let attachmentCounts = message.attachmentCounts
        
        if attachmentCounts.keys.contains(.image) || attachmentCounts.keys.contains(.video) {
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
