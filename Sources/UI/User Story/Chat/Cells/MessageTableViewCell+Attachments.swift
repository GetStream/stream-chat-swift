//
//  MessageTableViewCell+Attachments.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import RxSwift
import RxCocoa
import RxGesture

// MARK: - Attachments

extension MessageTableViewCell {
    
    func addAttachments(from message: Message,
                               tap: @escaping AttachmentTapAction,
                               actionTap: @escaping AttachmentActionTapAction,
                               reload: @escaping () -> Void) {
        guard let style = style else {
            return
        }
        
        let attachments = message.attachments
        let imageBackgroundColor = UIColor.color(by: message.user.name, isDark: !(messageLabel.textColor?.isDark ?? true))
        
        attachments.enumerated().forEach { index, attachment in
            func addGetures(_ preview: AttachmentPreviewProtocol, _ error: Error?) {
                guard !message.isEphemeral else {
                    return
                }
                
                guard let attachment = preview.attachment, (error == nil || !attachment.isImage) else {
                    preview.isUserInteractionEnabled = false
                    return
                }
                
                (preview as UIView).rx.anyGesture(TapControlEvent.default)
                    .subscribe(onNext: { _ in tap(attachment, index, attachments) })
                    .disposed(by: disposeBag)
            }
            
            let preview: AttachmentPreviewProtocol
            let isFileAttachment = attachment.type == .file
            
            if isFileAttachment {
                preview = createAttachmentFilePreview(with: attachment, style: style)
            } else {
                preview = createAttachmentPreview(with: attachment,
                                                  style: style,
                                                  imageBackgroundColor: imageBackgroundColor,
                                                  reload: reload)
            }
            
            messageStackView.insertArrangedSubview(preview, at: index)
            attachmentPreviews.append(preview)
            
            // File preview.
            if isFileAttachment {
                preview.update(maskImage: backgroundImageForAttachment(at: index)) { _, _ in }
                addGetures(preview, nil)
            } else if let preview = preview as? AttachmentPreview {
                // Ephemeral preview.
                if message.isEphemeral {
                    preview.update(maskImage: nil, addGetures)
                    preview.layer.cornerRadius = 0
                    
                    preview.actionsStackView.arrangedSubviews.forEach {
                        if let button = $0 as? UIButton {
                            button.rx.tap
                                .subscribe(onNext: { [weak button, weak preview] _ in
                                    if let button = button {
                                        preview?.actionsStackView.arrangedSubviews.forEach {
                                            if let button = $0 as? UIButton, let title = button.title(for: .normal) {
                                                button.isEnabled = title.lowercased() == "cancel"
                                            }
                                        }
                                        
                                        actionTap(message, button)
                                    }
                                })
                                .disposed(by: preview.disposeBag)
                        }
                    }
                } else {
                    // Image/Video preview.
                    preview.update(maskImage: maskImageForAttachment(at: index), addGetures)
                }
            }
        }
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
        
        preview.backgroundColor = attachment.isImage && attachment.actions.isEmpty
            ? style.chatBackgroundColor
            : (style.textColor.isDark ? .chatSuperLightGray : .chatDarkGray)
        
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
            if offset == 0, messageContainerViewImage == style.backgroundImages[.leftBottomCorner] {
                return style.transparentBackgroundImages[.leftBottomCorner]
            }
            
            return style.transparentBackgroundImages[.leftSide]
        }
        
        if offset == 0, messageContainerViewImage == style.backgroundImages[.rightBottomCorner] {
            return style.transparentBackgroundImages[.rightBottomCorner]
        }
        
        return style.transparentBackgroundImages[.rightSide]
    }
}
