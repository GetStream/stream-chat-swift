//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// The delegate used to handle Polls interactions in the message list.
public protocol PollAttachmentViewInjectorDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps in an option of the poll.
    func pollAttachmentView(
        _ pollAttachmentView: PollAttachmentView,
        didTapOnOption option: PollOption,
        for message: ChatMessage
    )
}

public class PollAttachmentViewInjector: AttachmentViewInjector {
    open lazy var pollAttachmentView: PollAttachmentView = contentView.components
        .pollAttachmentView
        .init()
        .withoutAutoresizingMaskConstraints

    public var pollAttachmentViewDelegate: PollAttachmentViewInjectorDelegate? {
        contentView.delegate as? PollAttachmentViewInjectorDelegate
    }

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

        guard let message = contentView.content else { return }
        guard let poll = message.poll else { return }
        guard let currentUserId = contentView.currentUserId else { return }

        pollAttachmentView.onOptionTap = { [weak self] option in
            guard let self = self else { return }
            pollAttachmentViewDelegate?.pollAttachmentView(
                self.pollAttachmentView,
                didTapOnOption: option,
                for: message
            )
        }
        pollAttachmentView.content = .init(poll: poll, currentUserId: currentUserId)
    }
}
