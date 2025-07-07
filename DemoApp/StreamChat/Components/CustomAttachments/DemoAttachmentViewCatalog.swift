//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI

class DemoAttachmentViewCatalog: AttachmentViewCatalog {
    override class func attachmentViewInjectorClassFor(message: ChatMessage, components: Components) -> AttachmentViewInjector.Type? {
        let hasLocationAttachment = message.sharedLocation != nil
        if hasLocationAttachment {
            return LocationAttachmentViewInjector.self
        }
        return super.attachmentViewInjectorClassFor(message: message, components: components)
    }
}
