//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate used `GiphyAttachmentViewInjector` to communicate user interactions.
public protocol FileActionContentViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps on attachment action
    func didTapOnAttachment(_ attachment: ChatMessageFileAttachment, at indexPath: IndexPath?)
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
        
        return attachmentListView.withoutAutoresizingMaskConstraints
    }()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleContentContainer.insertArrangedSubview(fileAttachmentView, at: 0, respectsLayoutMargins: false)
    }

    override open func contentViewDidUpdateContent() {
        fileAttachmentView.content = fileAttachments
    }
}

private extension FilesAttachmentViewInjector {
    var fileAttachments: [ChatMessageFileAttachment] {
        contentView.content?.fileAttachments ?? []
    }
}

public class MixedAttachmentViewInjector: AttachmentViewInjector {
    lazy var injectors = [GalleryAttachmentViewInjector(contentView), FilesAttachmentViewInjector(contentView)]
    
    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        injectors.forEach { $0.contentViewDidLayout(options: options) }
    }
    
    override open func contentViewDidUpdateContent() {
        injectors.forEach { $0.contentViewDidUpdateContent() }
    }
}
