//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate used `GiphyAttachmentViewInjector` to communicate user interactions.
public protocol GiphyActionContentViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps on attachment action
    func didTapOnAttachmentAction(_ action: AttachmentAction, at indexPath: IndexPath)
}

public class GiphyAttachmentViewInjector: AttachmentViewInjector {
    open lazy var giphyImageView: ChatMessageInteractiveAttachmentView = {
        let giphyView = contentView
            .components
            .giphyAttachmentView.init()
            .withoutAutoresizingMaskConstraints
        
        giphyView.contentMode = .scaleAspectFit
        giphyView.isUserInteractionEnabled = true
        giphyView.clipsToBounds = true
        giphyView.didTapOnAction = { [weak self] action in
            guard let indexPath = self?.contentView.indexPath?(),
                  let delegate = self?.contentView.delegate as? GiphyActionContentViewDelegate
            else { return }
         
            delegate.didTapOnAttachmentAction(action, at: indexPath)
        }
        return giphyView
    }()
    
    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleView?.clipsToBounds = true
        contentView.bubbleContentContainer.insertArrangedSubview(giphyImageView, at: 0, respectsLayoutMargins: false)
    }
    
    override open func contentViewDidUpdateContent() {
        giphyImageView.content = giphyAttachments.first
        print(giphyAttachments)
    }
}

private extension GiphyAttachmentViewInjector {
    var giphyAttachments: [ChatMessageGiphyAttachment] {
        contentView.content?.giphyAttachments ?? []
    }
}
