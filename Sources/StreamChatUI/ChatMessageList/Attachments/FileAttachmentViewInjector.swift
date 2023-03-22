//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate used `GiphyAttachmentViewInjector` to communicate user interactions.
public protocol FileActionContentViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps on attachment action
    func didTapOnAttachment(_ attachment: ChatMessageFileAttachment, at indexPath: IndexPath?)
}

/// The delegate that will be assigned on an AudioView and will be responsible to handle user interactions
/// from the view.
public protocol AudioAttachmentPresentationViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the view is about to be presented to determine if the attachment is ready for playback
    /// or if there are unmet requirements (e.g. download the attachment before playing)
    func audioAttachmentPresentationViewPlaybackContextForAttachment(
        _ attachment: ChatMessageFileAttachment
    ) -> AudioPlaybackContext

    /// Called when the user taps on the play button.
    func audioAttachmentPresentationViewBeginPayback(
        _ attachment: ChatMessageFileAttachment,
        with delegate: AudioPlayingDelegate
    )

    /// Called when the user taps on the pause button.
    func audioAttachmentPresentationViewPausePayback()

    /// Called when the user taps on the playback rate button.
    func audioAttachmentPresentationViewUpdatePlaybackRate(
        _ audioPlaybackRate: AudioPlaybackRate
    )

    /// Called when the user scrubs the progress view.
    func audioAttachmentPresentationViewSeek(to timeInterval: TimeInterval)
}

public class FilesAttachmentViewInjector: AttachmentViewInjector {
    open lazy var fileAttachmentView: ChatMessageFileAttachmentListView = {
        let attachmentListView = contentView
            .components
            .fileAttachmentListView
            .init()

        // We are injecting the itemViewProvider
        attachmentListView.itemViewProvider = { [weak self] in self?.makeItemView(for: $0) }

        attachmentListView.didTapOnAttachment = { [weak self] attachment in
            guard
                let delegate = self?.contentView.delegate as? FileActionContentViewDelegate
            else { return }
            delegate.didTapOnAttachment(attachment, at: self?.contentView.indexPath?())
        }

        return attachmentListView.withoutAutoresizingMaskConstraints
    }()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleContentContainer.insertArrangedSubview(
            fileAttachmentView,
            at: 0,
            respectsLayoutMargins: false
        )
    }

    override open func contentViewDidUpdateContent() {
        fileAttachmentView.content = fileAttachments
    }

    override public func contentViewDidPrepareForReuse() {
        fileAttachmentView.prepareForReuse()
    }

    open func makeItemView(
        for attachment: ChatMessageFileAttachment
    ) -> UIView {
        if attachment.file.type.isAudio,
           let audioAttachmentPresentationViewDelegate = contentView.delegate as? AudioAttachmentPresentationViewDelegate
        {
            return makeAudioView(
                for: attachment,
                delegate: audioAttachmentPresentationViewDelegate
            )
        }

        let item = contentView
            .components
            .fileAttachmentView
            .init()

        item.didTapOnAttachment = { [weak self] attachment in
            guard
                let delegate = self?.contentView.delegate as? FileActionContentViewDelegate
            else { return }
            delegate.didTapOnAttachment(attachment, at: self?.contentView.indexPath?())
        }
        item.content = attachment
        return item
    }

    open func makeAudioView(
        for attachment: ChatMessageFileAttachment,
        delegate: AudioAttachmentPresentationViewDelegate
    ) -> UIView {
        let item = contentView
            .components
            .audioAttachmentView
            .init()

        item.delegate = delegate
        item.content = attachment
        return item
    }
}

private extension FilesAttachmentViewInjector {
    var fileAttachments: [ChatMessageFileAttachment] {
        contentView.content?.fileAttachments ?? []
    }
}
