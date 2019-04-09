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
    
    private lazy var avatarView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.layer.cornerRadius = .messageAvatarRadius
        view.contentMode = .scaleAspectFill
        view.snp.makeConstraints { $0.width.height.equalTo(CGFloat.messageAvatarSize) }
        view.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
        view.isHidden = true
        return view
    }()
    
    private let avatarLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatAvatar
        label.textAlignment = .center
        label.isHidden = true
        label.preferredMaxLayoutWidth = .messageAvatarSize
        return label
    }()
    
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
    
    private lazy var messageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [messageContainerView, nameAndDateStackView, bottomPaddingView])
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
    
    private lazy var attachmentPreviewViews: [MessageAttachmentPreview] = []
    
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
            make.top.equalToSuperview().offset(CGFloat.messageSpacing)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(messagePadding)
            make.right.equalToSuperview().offset(-messagePadding)
        }
        
        update(isContinueMessage: false)
    }
    
    public func reset() {
        avatarView.isHidden = true
        avatarView.image = nil
        avatarView.backgroundColor = .white
        avatarLabel.text = nil
        avatarLabel.isHidden = true
        
        nameAndDateStackView.isHidden = true
        nameLabel.text = nil
        dateLabel.text = nil

        messageContainerView.isHidden = true
        update(isContinueMessage: false)
        messageLabel.text = nil

        paddingType = .regular
        
        free()
    }
    
    public func free() {
        attachmentPreviewViews.forEach { $0.removeFromSuperview() }
        attachmentPreviewViews = []
    }
    
    public func update(isContinueMessage: Bool) {
        guard let style = style else {
            return
        }
        
        messageContainerView.image = nil
        messageContainerView.layer.borderWidth = 0
        
        if let messageBackgroundImage = messageBackgroundImage(isContinueMessage: isContinueMessage) {
            messageContainerView.backgroundColor = style.chatBackgroundColor
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
        guard let style = style, style.leftBottomCornerBackgroundImage != nil else {
            return nil
        }
        
        return style.alignment == .left
            ? (isContinueMessage ? style.leftCornersBackgroundImage : style.leftBottomCornerBackgroundImage)
            : (isContinueMessage ? style.rightCornersBackgroundImage : style.rightBottomCornerBackgroundImage)
    }
    
    public func update(name: String?, date: Date) {
        nameAndDateStackView.isHidden = false
        
        if !nameLabel.isHidden, let name = name, !name.isEmpty {
            nameLabel.text = name
        }
        
        dateLabel.text = date.relative
    }
    
    public func update(message: String) {
        messageContainerView.isHidden = message.isEmpty
        messageLabel.text = message
    }
    
    public func update(avatarURL: URL?, name: String) {
        avatarView.isHidden = false
        
        guard let avatarURL = avatarURL else {
            showAvatarLabel(with: name)
            return
        }
        
        let imageSize = avatarView.bounds.width * UIScreen.main.scale
        let request = ImageRequest(url: avatarURL, targetSize: CGSize(width: imageSize, height: imageSize), contentMode: .aspectFill)
        
        ImagePipeline.shared.loadImage(with: request) { [weak self] response, error in
            self?.avatarView.image = response?.image
        }
    }
    
    public func add(attachments: [MessageAttachment], userName: String) {
        guard let style = style else {
            return
        }
        
        attachments.enumerated().forEach { offset, attachment in
            let preview = MessageAttachmentPreview(frame: .zero)
            preview.maxWidth = maxMessageWidth
            preview.tintColor = style.textColor
            preview.backgroundColor = style.chatBackgroundColor.isDark ? .chatDarkGray : .chatSuperLightGray
            preview.imageView.backgroundColor = color(by: userName)
            preview.layer.cornerRadius = style.cornerRadius
            preview.type = attachment.type
            messageStackView.insertArrangedSubview(preview, at: offset)
            attachmentPreviewViews.append(preview)
            
            let maskImage: UIImage?
            
            if style.alignment == .left {
                maskImage = offset == 0 ? messageContainerView.image : style.leftCornersBackgroundImage
            } else {
                maskImage = offset == 0 ? messageContainerView.image : style.rightCornersBackgroundImage
            }
            
            preview.update(attachment: attachment, maskImage: maskImage)
        }
        
        update(isContinueMessage: true)
    }
    
    private func showAvatarLabel(with name: String) {
        if name.contains(" ") {
            let words = name.split(separator: " ")
            
            if let a = String(describing: words[0]).first, let b = String(describing: words[1]).first {
                avatarLabel.text = String(a).appending(String(b)).uppercased()
            }
        } else {
            avatarLabel.text = name.first?.uppercased()
        }
        
        avatarView.backgroundColor = color(by: name)
        avatarLabel.isHidden = false
        avatarLabel.textColor = avatarView.backgroundColor?.withAlphaComponent(0.3)
    }
    
    private func color(by name: String) -> UIColor {
        var brightness: CGFloat = 0.5
        
        if let backgroundColor = backgroundColor {
            brightness = backgroundColor.isDark ? 1 : 0.5
        }
        
        let hue: CGFloat = abs(((CGFloat(name.hashValue) / CGFloat(Int.max)) * 15) / 15)
        return .transparent(hue: hue, brightness: brightness)
    }
}

public enum MessageTableViewCellPaddingType: String {
    case regular
    case small
}
