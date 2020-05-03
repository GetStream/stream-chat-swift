//
//  MessageTableViewCell+Attachments.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import RxSwift
import RxCocoa
import RxGesture

// MARK: - Attachments

extension MessageTableViewCell {
    
    func addAttachment(_ attachment: Attachment,
                       at index: Int,
                       from message: Message,
                       tap: @escaping AttachmentTapAction,
                       actionTap: @escaping AttachmentActionTapAction,
                       reload: @escaping () -> Void) {
        func addGetures(_ preview: AttachmentPreview, _ error: Error?) {
            guard !message.isEphemeral else {
                return
            }
            
            guard let attachment = preview.attachment, (error == nil || !attachment.isImage) else {
                preview.isUserInteractionEnabled = false
                return
            }
            
            (preview as UIView).rx.anyGesture(TapControlEvent.default)
                .subscribe(onNext: { _ in tap(attachment, index, message.attachments) })
                .disposed(by: disposeBag)
        }
        
        let preview: AttachmentPreview
        let isFileAttachment = attachment.type == .file
        
        if isFileAttachment {
            preview = FileAttachmentPreview(frame: .zero)
            preview.setup(attachment: attachment, style: style)
            preview.snp.makeConstraints { $0.height.equalTo(CGFloat.attachmentFilePreviewHeight).priority(999) }
        } else {
            let imagePreview = ImageAttachmentPreview(frame: .zero)
            imagePreview.setup(attachment: attachment, style: style)
            imagePreview.forceToReload = reload
            preview = imagePreview
        }
        
        preview.index = index
        messageStackView.insertArrangedSubview(preview, at: index)
        attachmentPreviews.append(preview)
        
        guard let imagePreview = preview as? ImageAttachmentPreview else {
            // File preview.
            preview.update()
            preview.apply(imageMask: backgroundImageForAttachment(at: index))
            addGetures(preview, nil)
            return
        }
        
        // Image/Video preview.
        guard message.isEphemeral else {
            imagePreview.update { [weak self, weak imagePreview] in
                imagePreview?.apply(imageMask: self?.imageMaskForAttachment(at: index))
                addGetures($0, $1)
            }
            return
        }
        
        // Ephemeral preview.
        imagePreview.update(addGetures)
        
        imagePreview.actionsStackView.arrangedSubviews.forEach {
            if let button = $0 as? UIButton {
                button.rx.tap
                    .subscribe(onNext: { [weak button, weak imagePreview] _ in
                        if let button = button {
                            imagePreview?.actionsStackView.arrangedSubviews.forEach {
                                if let button = $0 as? UIButton, let title = button.title(for: .normal) {
                                    button.isEnabled = title.lowercased() == "cancel"
                                }
                            }
                            
                            actionTap(message, button)
                        }
                    })
                    .disposed(by: imagePreview.disposeBag)
            }
        }
    }
    
    func backgroundImageForAttachment(at offset: Int) -> UIImage? {
        guard style.hasBackgroundImage else {
            return nil
        }
        
        if style.alignment == .left {
            return offset == 0 ? messageContainerView.image : style.backgroundImages[.rightSide]?.image(for: traitCollection)
        }
        
        return offset == 0 ? messageContainerView.image : style.backgroundImages[.rightSide]?.image(for: traitCollection)
    }
    
    private func imageMaskForAttachment(at offset: Int) -> UIImage? {
        guard style.hasBackgroundImage, let messageContainerViewImage = messageContainerView.image else {
            return nil
        }
        
        if style.alignment == .left {
            if offset == 0,
                messageContainerViewImage == style.backgroundImages[.pointedLeftBottom]?.image(for: traitCollection) {
                return style.transparentBackgroundImages[.pointedLeftBottom]?.image(for: traitCollection)
            }
            
            return style.transparentBackgroundImages[.rightSide]?.image(for: traitCollection)
        }
        
        if offset == 0, messageContainerViewImage == style.backgroundImages[.pointedRightBottom]?.image(for: traitCollection) {
            return style.transparentBackgroundImages[.pointedRightBottom]?.image(for: traitCollection)
        }
        
        return style.transparentBackgroundImages[.leftSide]?.image(for: traitCollection)
    }
}
