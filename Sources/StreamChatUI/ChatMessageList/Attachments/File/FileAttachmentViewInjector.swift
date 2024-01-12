//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate used `FileAttachmentViewInjector` to communicate user interactions.
public protocol FileActionContentViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps on the attachment.
    func didTapOnAttachment(_ attachment: ChatMessageFileAttachment, at indexPath: IndexPath?)
    
    /// Called when the user taps on the action of the attachment. (Ex: Retry)
    func didTapActionOnAttachment(_ attachment: ChatMessageFileAttachment, at indexPath: IndexPath?)
}

public class FilesAttachmentViewInjector: AttachmentViewInjector {
    open lazy var fileAttachmentView: ChatMessageFileAttachmentListView = {
        let attachmentListView = contentView
            .components
            .fileAttachmentListView
            .init()

        attachmentListView.didTapOnAttachment = { [weak self] attachment in
            guard
                let delegate = self?.contentView.delegate as? FileActionContentViewDelegate
            else { return }
            delegate.didTapOnAttachment(attachment, at: self?.contentView.indexPath?())
        }

        attachmentListView.didTapActionOnAttachment = { [weak self] attachment in
            guard
                let delegate = self?.contentView.delegate as? FileActionContentViewDelegate
            else { return }
            delegate.didTapActionOnAttachment(attachment, at: self?.contentView.indexPath?())
        }

        return attachmentListView.withoutAutoresizingMaskConstraints
    }()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleContentContainer.insertArrangedSubview(fileAttachmentView, at: 0, respectsLayoutMargins: false)
    }

    override open func contentViewDidUpdateContent() {
        fileAttachmentView.content = fileAttachments
    }
}

public extension FilesAttachmentViewInjector {
    var fileAttachments: [ChatMessageFileAttachment] {
        if fileAttachmentView.components.isVoiceRecordingEnabled {
            return contentView.content?.fileAttachments ?? []
        } else {
            let fileAttachments = contentView.content?.fileAttachments ?? []
            let voiceRecordingAttachments = (contentView.content?.voiceRecordingAttachments ?? [])
                .compactMap { $0.asAttachment(payloadType: FileAttachmentPayload.self) }
            return fileAttachments + voiceRecordingAttachments
        }
    }
}
