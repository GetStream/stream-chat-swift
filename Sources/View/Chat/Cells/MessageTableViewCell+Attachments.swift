//
//  MessageTableViewCell+Attachments.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

// MARK: - Attachments

extension MessageTableViewCell {
    
    public func add(attachments: [Attachment],
                    userName: String,
                    tap: @escaping (_ attachment: Attachment, _ at: Int, _ attachments: [Attachment]) -> Void,
                    reload: @escaping () -> Void) {
        guard let style = style else {
            return
        }
        
        attachments.enumerated().forEach { index, attachment in
            let preview: AttachmentPreviewProtocol
            
            if attachment.type == .file {
                preview = createAttachmentFilePreview(with: attachment, style: style)
            } else {
                preview = createAttachmentPreview(with: attachment,
                                                  style: style,
                                                  imageBackgroundColor: .color(by: userName, isDark: backgroundColor?.isDark ?? false),
                                                  reload: reload)
            }
            
            messageStackView.insertArrangedSubview(preview, at: index)
            attachmentPreviews.append(preview)
            
            if attachment.type == .file {
                preview.update(maskImage: backgroundImageForAttachment(at: index))
            } else {
                preview.update(maskImage: maskImageForAttachment(at: index))
            }
            
            (preview as UIView).rx.tapGesture()
                .when(.recognized)
                .subscribe(onNext: { _ in tap(attachment, index, attachments) })
                .disposed(by: preview.disposeBag)
        }
        
        updateBackground(isContinueMessage: true)
    }
    
    private func createAttachmentPreview(with attachment: Attachment,
                                         style: MessageViewStyle,
                                         imageBackgroundColor: UIColor,
                                         reload: @escaping () -> Void) -> AttachmentPreview {
        let preview = AttachmentPreview(frame: .zero)
        preview.maxWidth = .messageTextMaxWidth
        preview.tintColor = style.textColor
        preview.imageView.backgroundColor = imageBackgroundColor
        preview.layer.cornerRadius = style.cornerRadius
        preview.attachment = attachment
        preview.forceToReload = reload
        
        preview.backgroundColor = attachment.isImage
            ? style.chatBackgroundColor
            : (style.chatBackgroundColor.isDark ? .chatDarkGray : .chatSuperLightGray)
        
        return preview
    }
    
    private func createAttachmentFilePreview(with attachment: Attachment,
                                             style: MessageViewStyle) -> AttachmentFilePreview {
        let preview = AttachmentFilePreview(frame: .zero)
        preview.attachment = attachment
        preview.backgroundColor = style.chatBackgroundColor
        preview.snp.makeConstraints { $0.height.equalTo(CGFloat.attachmentFilePreviewHeight).priority(999) }
        return preview
    }
    
    private func backgroundImageForAttachment(at offset: Int) -> UIImage? {
        guard let style = style, style.hasBackgroundImage else {
            return nil
        }
        
        if style.alignment == .left {
            return offset == 0 ? messageContainerView.image : style.backgroundImages[.leftSide]
        }
        
        return offset == 0 ? messageContainerView.image : style.backgroundImages[.rightSide]
    }
    
    private func maskImageForAttachment(at offset: Int) -> UIImage? {
        guard let style = style, style.hasBackgroundImage, let messageContainerViewImage = messageContainerView.image else {
            return nil
        }
        
        if style.alignment == .left {
            return offset == 0 || messageContainerViewImage == style.backgroundImages[.leftBottomCorner]
                ? style.transparentBackgroundImages[.leftBottomCorner]
                : style.transparentBackgroundImages[.leftSide]
        }
        
        return offset == 0 || messageContainerViewImage == style.backgroundImages[.rightBottomCorner]
            ? style.transparentBackgroundImages[.rightBottomCorner]
            : style.transparentBackgroundImages[.rightSide]
    }
}
