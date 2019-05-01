//
//  MessageTableViewCell.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import Nuke

final class MessageTableViewCell: UITableViewCell, Reusable {
    
    let avatarView = AvatarView(cornerRadius: .messageAvatarRadius)
    
    //    private let reactionsContainer = UIImageView(frame: .zero)
    //
    //    private let reactionsLabel: UILabel = {
    //        let label = UILabel(frame: .zero)
    //        label.textAlignment = .center
    //        return label
    //    }()
    //
    //    private(set) lazy var reactionButton: UIButton = {
    //        let button = UIButton(type: .custom)
    //        button.setImage(UIImage.Icons.happy, for: .normal)
    //        button.tintColor = .chatGray
    //        return button
    //    }()
    
    private lazy var nameAndDateStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, dateLabel])
        stackView.axis = .horizontal
        stackView.spacing = .messageSpacing
        stackView.snp.makeConstraints { $0.height.equalTo(CGFloat.messageAvatarRadius).priority(999) }
        stackView.isHidden = true
        return stackView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatBoldSmall
        label.textColor = .chatGray
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.chatMedium.withTraits([.traitItalic])
        label.textColor = .chatGray
        label.isHidden = true
        return label
    }()

    private lazy var messageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [messageContainerView, infoLabel, nameAndDateStackView, bottomPaddingView])
        stackView.axis = .vertical
        stackView.spacing = .messageSpacing
        return stackView
    }()
    
    private let messageContainerView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.isHidden = true
        return imageView
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatRegular
        label.textColor = .black
        label.preferredMaxLayoutWidth = maxMessageWidth
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var attachmentPreviews: [AttachmentPreviewProtocol] = []
    
    private let bottomPaddingView: UIView = {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.snp.makeConstraints { $0.height.equalTo(CGFloat.messageBottomPadding).priority(999) }
        return view
    }()
    
    private var messagePadding: CGFloat {
        return .messageEdgePadding + .messageAvatarSize + .messageInnerPadding
    }
    
    private var maxMessageWidth: CGFloat {
        return UIScreen.main.bounds.width - 2 * messagePadding
    }
    
    public var paddingType: MessageTableViewCellPaddingType = .regular {
        didSet { bottomPaddingView.isHidden = paddingType == .small }
    }
    
    public var style: MessageViewStyle? {
        didSet { setup() }
    }
    
    override func prepareForReuse() {
        reset()
        super.prepareForReuse()
    }
    
    private func setup() {
        guard let style = style else {
            return
        }
        
        selectionStyle = .none
        backgroundColor = style.chatBackgroundColor
        dateLabel.font = style.infoFont
        dateLabel.textColor = style.infoColor
        dateLabel.backgroundColor = backgroundColor
        bottomPaddingView.backgroundColor = backgroundColor
        
        messageLabel.font = style.font
        messageLabel.textColor = style.textColor
        messageLabel.backgroundColor = style.backgroundColor
        
        if style.alignment == .left {
            nameLabel.font = style.nameFont
            nameLabel.textColor = style.infoColor
            nameLabel.backgroundColor = backgroundColor
        } else {
            nameLabel.isHidden = true
        }
        
        // Avatar
        contentView.addSubview(avatarView)
        
        avatarView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-CGFloat.messageBottomPadding)
            
            if style.alignment == .left {
                make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            } else {
                make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            }
        }
        
        // Message Stack View
        
        messageContainerView.addSubview(messageLabel)
        
        messageLabel.snp.makeConstraints { make in
            make.left.equalTo(CGFloat.messageHorizontalInset)
            make.right.equalTo(-CGFloat.messageHorizontalInset)
            make.top.equalTo(CGFloat.messageVerticalInset).priority(999)
            make.bottom.equalTo(-CGFloat.messageVerticalInset).priority(999)
        }
        
        contentView.addSubview(messageStackView)
        messageStackView.alignment = style.alignment == .left ? .leading : .trailing
        
        messageStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.messageSpacing) //  + .reactionsHeight + .messageSpacing
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(messagePadding)
            make.right.equalToSuperview().offset(-messagePadding)
        }
        
        // Reactions.
        //        reactionsContainer.addSubview(reactionsLabel)
        //        reactionsContainer.image = style.reactionViewStyle.backgroundImage
        //        contentView.addSubview(reactionsContainer)
        //
        //        reactionsContainer.snp.makeConstraints { make in
        //            make.top.equalToSuperview().offset(CGFloat.messageSpacing)
        //            make.right.equalTo(messageLabel.snp.right).offset(CGFloat.reactionsHeight - 4)
        //            make.height.equalTo(CGFloat.reactionsFullHeight).priority(999)
        //        }
        //
        //        reactionsLabel.font = style.reactionViewStyle.font
        //        reactionsLabel.textColor = style.reactionViewStyle.textColor
        //
        //        reactionsLabel.snp.makeConstraints { make in
        //            make.left.equalToSuperview().offset(CGFloat.reactionsTextPagging)
        //            make.right.equalToSuperview().offset(-CGFloat.reactionsTextPagging)
        //            make.top.equalToSuperview()
        //            make.height.equalTo(CGFloat.reactionsHeight)
        //        }
        //
        //        if style.alignment == .left {
        //            reactionButton.backgroundColor = style.chatBackgroundColor
        //            contentView.insertSubview(reactionButton, at: 0)
        //
        //            reactionButton.snp.makeConstraints { make in
        //                make.top.equalTo(messageLabel.snp.top).offset(-15)
        //                make.centerX.equalTo(reactionsContainer.snp.right).offset(1)
        //                make.width.equalTo(30)
        //                make.height.equalTo(30)
        //            }
        //        }
    }
    
    public func reset() {
        avatarView.reset()
        avatarView.isHidden = true
        avatarView.backgroundColor = backgroundColor
        
        nameAndDateStackView.isHidden = true
        nameLabel.text = nil
        dateLabel.text = nil
        
        infoLabel.isHidden = true
        infoLabel.text = nil
        
        messageContainerView.isHidden = true
        messageContainerView.image = nil
        messageContainerView.layer.borderWidth = 0
        messageContainerView.backgroundColor = style?.chatBackgroundColor
        messageLabel.text = nil
        messageLabel.font = style?.font
        messageLabel.backgroundColor = style?.backgroundColor
        
        paddingType = .regular
        
        free()
    }
    
    public func free() {
        attachmentPreviews.forEach { $0.removeFromSuperview() }
        attachmentPreviews = []
    }
    
    public func updateBackground(isContinueMessage: Bool) {
        guard let style = style else {
            return
        }
        
        if let text = messageLabel.text, text.messageContainsOnlyEmoji {
            messageLabel.backgroundColor = style.chatBackgroundColor
            return
        }
        
        if let messageBackgroundImage = messageBackgroundImage(isContinueMessage: isContinueMessage) {
            messageContainerView.image = messageBackgroundImage
        } else {
            messageContainerView.backgroundColor = style.backgroundColor
            
            if style.borderWidth > 0 {
                messageContainerView.layer.borderWidth = style.borderWidth
                messageContainerView.layer.borderColor = style.borderColor.cgColor
            }
        }
    }
    
    private func messageBackgroundImage(isContinueMessage: Bool) -> UIImage? {
        guard let style = style, style.hasBackgroundImage else {
            return nil
        }
        
        return style.alignment == .left
            ? (isContinueMessage
                ? style.backgroundImages[.leftSide(transparent: false)]
                : style.backgroundImages[.leftBottomCorner(transparent: false)])
            : (isContinueMessage
                ? style.backgroundImages[.rightSide(transparent: false)]
                : style.backgroundImages[.rightBottomCorner(transparent: false)])
    }
    
    public func update(name: String? = nil, date: Date) {
        nameAndDateStackView.isHidden = false
        
        if style?.alignment == .left, let name = name, !name.isEmpty {
            nameLabel.isHidden = false
            nameLabel.text = name
        } else {
            nameLabel.isHidden = true
        }
        
        dateLabel.text = date.relative
    }
    
    public func update(info: String?, date: Date? = nil) {
        guard let info = info else {
            return
        }
        
        infoLabel.text = info
        infoLabel.isHidden = false
    }

    public func update(message: String) {
        messageContainerView.isHidden = message.isEmpty
        messageLabel.text = message
        
        if let font = style?.emojiFont, message.messageContainsOnlyEmoji {
            messageLabel.font = font
        }
    }
    
    public func add(attachments: [Attachment], userName: String, reload: @escaping () -> Void) {
        guard let style = style else {
            return
        }
        
        attachments.enumerated().forEach { offset, attachment in
            let preview: AttachmentPreviewProtocol
            
            if attachment.type == .file {
                preview = createAttachmentFilePreview(with: attachment, style: style)
            } else {
                preview = createAttachmentPreview(with: attachment,
                                                  style: style,
                                                  imageBackgroundColor: .color(by: userName,
                                                                               isDark: backgroundColor?.isDark ?? false),
                                                  reload: reload)
            }
            
            messageStackView.insertArrangedSubview(preview, at: offset)
            attachmentPreviews.append(preview)
            
            if attachment.type == .file {
                preview.update(maskImage: backgroundImageForAttachment(at: offset))
            } else {
                preview.update(maskImage: maskImageForAttachment(at: offset))
            }
        }
        
        updateBackground(isContinueMessage: true)
    }
    
    private func createAttachmentPreview(with attachment: Attachment,
                                         style: MessageViewStyle,
                                         imageBackgroundColor: UIColor,
                                         reload: @escaping () -> Void) -> AttachmentPreviewProtocol {
        let preview = AttachmentPreview(frame: .zero)
        preview.maxWidth = maxMessageWidth
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
                                             style: MessageViewStyle) -> AttachmentPreviewProtocol {
        let preview = AttachmentFilePreview(frame: .zero)
        preview.backgroundColor = style.chatBackgroundColor
        preview.snp.makeConstraints { $0.height.equalTo(CGFloat.attachmentFilePreviewHeight).priority(999) }
        return preview
    }
    
    private func backgroundImageForAttachment(at offset: Int) -> UIImage? {
        guard let style = style, style.hasBackgroundImage else {
            return nil
        }
        
        if style.alignment == .left {
            return offset == 0 ? messageContainerView.image : style.backgroundImages[.leftSide(transparent: false)]
        }
        
        return offset == 0 ? messageContainerView.image : style.backgroundImages[.rightSide(transparent: false)]
    }
    
    private func maskImageForAttachment(at offset: Int) -> UIImage? {
        guard let style = style, style.hasBackgroundImage, let messageContainerViewImage = messageContainerView.image else {
            return nil
        }
        
        if style.alignment == .left {
            return offset == 0 || messageContainerViewImage == style.backgroundImages[.leftBottomCorner(transparent: false)]
                ? style.backgroundImages[.leftBottomCorner(transparent: true)]
                : style.backgroundImages[.leftSide(transparent: true)]
        }
        
        return offset == 0 || messageContainerViewImage == style.backgroundImages[.rightBottomCorner(transparent: false)]
            ? style.backgroundImages[.rightBottomCorner(transparent: true)]
            : style.backgroundImages[.rightSide(transparent: true)]
    }
}

public enum MessageTableViewCellPaddingType: String {
    case regular
    case small
}
