//
//  ChatViewController+Attachments.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 09/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension ChatViewController {
    
    func stopGifsAnimations() {
        visibleAttachmentPreviews { attachmentPreview in
            if attachmentPreview.isGifImage {
                attachmentPreview.imageView.stopAnimatingGif()
            }
        }
    }
    
    func startGifsAnimations() {
        visibleAttachmentPreviews { attachmentPreview in
            if attachmentPreview.isGifImage {
                attachmentPreview.imageView.startAnimatingGif()
            }
        }
    }
    
    private func visibleAttachmentPreviews(action: (_ attachmentPreview: ImageAttachmentPreview) -> Void) {
        tableView.visibleCells.forEach { cell in
            guard let messageCell = cell as? MessageTableViewCell else {
                return
            }
            
            messageCell.attachmentPreviews.forEach {
                if let attachmentPreview = $0 as? ImageAttachmentPreview {
                    action(attachmentPreview)
                }
            }
        }
    }
}
