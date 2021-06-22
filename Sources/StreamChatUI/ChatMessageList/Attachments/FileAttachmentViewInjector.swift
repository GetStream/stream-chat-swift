//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate used `GiphyAttachmentViewInjector` to communicate user interactions.
public protocol FileActionContentViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps on attachment action
    func didTapOnAttachment(_ attachment: ChatMessageFileAttachment, at indexPath: IndexPath?)
}

public typealias FilesAttachmentViewInjector = _FilesAttachmentViewInjector<NoExtraData>

public class _FilesAttachmentViewInjector<ExtraData: ExtraDataTypes>: _AttachmentViewInjector<ExtraData> {
    open lazy var fileAttachmentView: _ChatMessageFileAttachmentListView<ExtraData> = {
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
        
        return attachmentListView.withoutAutoresizingMaskConstraints
    }()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleContentContainer.insertArrangedSubview(fileAttachmentView, at: 0, respectsLayoutMargins: false)
    }

    override open func contentViewDidUpdateContent() {
        fileAttachmentView.content = fileAttachments
    }
}

private extension _FilesAttachmentViewInjector {
    var fileAttachments: [ChatMessageFileAttachment] {
        contentView.content?.fileAttachments ?? []
    }
}
