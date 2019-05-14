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
    
    public func addAttachments(from message: Message,
                               tap: @escaping AttachmentTapAction,
                               longPress: @escaping LongPressAction,
                               actionTap: @escaping AttachmentActionTapAction,
                               reload: @escaping () -> Void) {
        guard let style = style else {
            return
        }
        
        let attachments = message.attachments
        let imageBackgroundColor = UIColor.color(by: message.user.name, isDark: backgroundColor?.isDark ?? false)
        
        attachments.enumerated().forEach { index, attachment in
            let preview: AttachmentPreviewProtocol
            
            if attachment.type == .file {
                preview = createAttachmentFilePreview(with: attachment, style: style)
            } else {
                preview = createAttachmentPreview(with: attachment,
                                                  style: style,
                                                  imageBackgroundColor: imageBackgroundColor,
                                                  reload: reload)
            }
            
            messageStackView.insertArrangedSubview(preview, at: index)
            attachmentPreviews.append(preview)
            
            if attachment.type == .file {
                preview.update(maskImage: backgroundImageForAttachment(at: index))
                
            } else if !message.isEphemeral {
                preview.update(maskImage: maskImageForAttachment(at: index))
                
            } else if let preview = preview as? AttachmentPreview {
                preview.update(maskImage: nil)
                preview.layer.cornerRadius = 0
                
                preview.actionsStackView.arrangedSubviews.forEach {
                    if let button = $0 as? UIButton {
                        button.rx.tap
                            .subscribe(onNext: { [weak button, weak preview] _ in
                                if let button = button {
                                    preview?.actionsStackView.arrangedSubviews.forEach { ($0 as? UIButton)?.isEnabled = false }
                                    actionTap(message, button)
                                }
                            })
                            .disposed(by: preview.disposeBag)
                    }
                }
            }
            
            guard !message.isEphemeral else {
                return
            }
            
            (preview as UIView).rx
                .anyGesture((.tap(configuration: { $1.simultaneousRecognitionPolicy = .never }), when: .recognized),
                            (.longPress(configuration: { gesture, delegate in
                                gesture.minimumPressDuration = MessageTableViewCell.longPressMinimumDuration
                                delegate.simultaneousRecognitionPolicy = .never
                            }), when: .began))
                .subscribe(onNext: { [weak self] gesture in
                    if let self = self {
                        if gesture is UITapGestureRecognizer {
                            tap(attachment, index, attachments)
                        } else {
                            longPress(self, message)
                        }
                    }
                })
                .disposed(by: preview.disposeBag)
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
        
        preview.backgroundColor = attachment.isImageOrVideo && attachment.actions.isEmpty
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
