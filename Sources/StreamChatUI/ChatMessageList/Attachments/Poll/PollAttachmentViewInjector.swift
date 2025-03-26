//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// The delegate used to handle Polls interactions in the message list.
@preconcurrency @MainActor public protocol PollAttachmentViewInjectorDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps in an option of the poll.
    func pollAttachmentView(
        _ pollAttachmentView: PollAttachmentView,
        didTapOption option: PollOption,
        in message: ChatMessage
    )

    /// Called when the user ends the poll.
    func pollAttachmentView(
        _ pollAttachmentView: PollAttachmentView,
        didTapEndPoll poll: Poll,
        in message: ChatMessage
    )

    /// Called when the user taps on the button to show the poll results.
    func pollAttachmentView(
        _ pollAttachmentView: PollAttachmentView,
        didTapResultsOfPoll poll: Poll,
        in message: ChatMessage
    )

    /// Called when the user taps on the button to show the poll comments.
    func pollAttachmentView(
        _ pollAttachmentView: PollAttachmentView,
        didTapCommentsOfPoll poll: Poll,
        in message: ChatMessage
    )

    /// Called when the user taps on the button to suggest a new option.
    func pollAttachmentView(
        _ pollAttachmentView: PollAttachmentView,
        didTapSuggestOptionForPoll poll: Poll,
        in message: ChatMessage
    )

    /// Called when the user taps on the button to show the poll comments.
    func pollAttachmentView(
        _ pollAttachmentView: PollAttachmentView,
        didTapAddCommentOnPoll poll: Poll,
        in message: ChatMessage
    )

    /// Called when the user taps on the button to show all the options of the poll.
    func pollAttachmentView(
        _ pollAttachmentView: PollAttachmentView,
        didTapShowAllOptionsForPoll poll: Poll,
        in message: ChatMessage
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
            self.pollAttachmentViewDelegate?.pollAttachmentView(self.pollAttachmentView, didTapOption: option, in: message)
        }
        pollAttachmentView.onEndTap = { [weak self] poll in
            guard let self = self else { return }
            self.pollAttachmentViewDelegate?.pollAttachmentView(self.pollAttachmentView, didTapEndPoll: poll, in: message)
        }
        pollAttachmentView.onResultsTap = { [weak self] poll in
            guard let self = self else { return }
            self.pollAttachmentViewDelegate?.pollAttachmentView(self.pollAttachmentView, didTapResultsOfPoll: poll, in: message)
        }
        pollAttachmentView.onCommentsTap = { [weak self] poll in
            guard let self = self else { return }
            self.pollAttachmentViewDelegate?.pollAttachmentView(self.pollAttachmentView, didTapCommentsOfPoll: poll, in: message)
        }
        pollAttachmentView.onAddCommentTap = { [weak self] poll in
            guard let self = self else { return }
            self.pollAttachmentViewDelegate?.pollAttachmentView(self.pollAttachmentView, didTapAddCommentOnPoll: poll, in: message)
        }
        pollAttachmentView.onSuggestOptionTap = { [weak self] poll in
            guard let self = self else { return }
            self.pollAttachmentViewDelegate?.pollAttachmentView(self.pollAttachmentView, didTapSuggestOptionForPoll: poll, in: message)
        }
        pollAttachmentView.onShowAllOptionsTap = { [weak self] poll in
            guard let self = self else { return }
            self.pollAttachmentViewDelegate?.pollAttachmentView(
                self.pollAttachmentView,
                didTapShowAllOptionsForPoll: poll,
                in: message
            )
        }

        pollAttachmentView.content = .init(poll: poll, currentUserId: currentUserId)
    }
}
