//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public class PollAttachmentViewInjector: AttachmentViewInjector {
    open lazy var pollAttachmentView: PollAttachmentView = contentView.components
        .pollAttachmentView
        .init()
        .withoutAutoresizingMaskConstraints

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(
            pollAttachmentView,
            at: 0,
            respectsLayoutMargins: false
        )
    }

    override open func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        guard let poll = contentView.content?.poll else { return }
        pollAttachmentView.content = .init(poll: poll)
    }
}
