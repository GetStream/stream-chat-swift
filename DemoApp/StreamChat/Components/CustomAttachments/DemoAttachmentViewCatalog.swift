//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI

class DemoAttachmentViewCatalog: AttachmentViewCatalog {
    override class func attachmentViewInjectorClassFor(message: ChatMessage, components: Components) -> AttachmentViewInjector.Type? {
        let hasMultipleAttachmentTypes = message.attachmentCounts.keys.count > 1
        let hasLocationAttachment = message.attachmentCounts.keys.contains(.location)
        if AppConfig.shared.demoAppConfig.isLocationAttachmentsEnabled && hasLocationAttachment {
            if hasMultipleAttachmentTypes {
                return MixedAttachmentViewInjector.self
            }
            return LocationAttachmentViewInjector.self
        }

        return super.attachmentViewInjectorClassFor(message: message, components: components)
    }
}
