//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate used in `LinkAttachmentViewInjector` to communicate user interactions.
public protocol LinkPreviewViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps the link preview.
    func didTapOnLinkAttachment(
        _ attachment: ChatMessageLinkAttachment,
        at indexPath: IndexPath?
    )
}

/// View injector for showing link attachments.
public typealias LinkAttachmentViewInjector = _LinkAttachmentViewInjector<NoExtraData>

/// View injector for showing link attachments.
open class _LinkAttachmentViewInjector<ExtraData: ExtraDataTypes>: _AttachmentViewInjector<ExtraData> {
    open private(set) lazy var linkPreviewView = _ChatMessageLinkPreviewView<ExtraData>()
        .withoutAutoresizingMaskConstraints
    
    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleView?.clipsToBounds = true
        contentView.bubbleContentContainer.addArrangedSubview(linkPreviewView, respectsLayoutMargins: true)
        
        linkPreviewView.addTarget(self, action: #selector(handleTapOnAttachment), for: .touchUpInside)
    }
    
    override open func contentViewDidUpdateContent() {
        linkPreviewView.content = contentView.content?.linkAttachments.first
        contentView.bubbleView?.backgroundColor = contentView.appearance.colorPalette.highlightedAccentBackground1
    }
    
    /// Triggered when `attachment` is tapped.
    @objc
    open func handleTapOnAttachment() {
        guard
            let attachment = linkPreviewView.content
        else { return }
        (contentView.delegate as? LinkPreviewViewDelegate)?
            .didTapOnLinkAttachment(
                attachment,
                at: contentView.indexPath?()
            )
    }
}
