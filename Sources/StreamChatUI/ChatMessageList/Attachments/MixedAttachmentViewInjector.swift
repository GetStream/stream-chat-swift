//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The injector used to combine multiple types of attachment views.
public class MixedAttachmentViewInjector: AttachmentViewInjector {
    open lazy var injectors = [
        contentView.components.galleryAttachmentInjector.init(contentView),
        contentView.components.filesAttachmentInjector.init(contentView)
    ]

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        injectors.forEach { $0.contentViewDidLayout(options: options) }
    }

    override open func contentViewDidUpdateContent() {
        injectors.forEach { $0.contentViewDidUpdateContent() }
    }
}
