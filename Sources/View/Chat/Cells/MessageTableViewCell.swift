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
    
    private let reactionsContainer = UIImageView(frame: .zero)
    private let reactionsTailImage = UIImageView(frame: .zero)

    private let reactionsLabel: UILabel = {
        let label = UILabel(frame: .zero)
//        label.textAlignment = .center
        return label
    }()
    
    //    private(set) lazy var reactionButton: UIButton = {
    //        let button = UIButton(type: .custom)
    //        button.setImage(UIImage.Icons.happy, for: .normal)
    //        button.tintColor = .chatGray
    //        return button
    //    }()
    
    private(set) lazy var nameAndDateStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, dateLabel])
        stackView.axis = .horizontal
        stackView.spacing = .messageSpacing
        stackView.snp.makeConstraints { $0.height.equalTo(CGFloat.messageAvatarRadius).priority(999) }
        stackView.isHidden = true
        return stackView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatBoldSmall
        label.textColor = .chatGray
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        return label
    }()
    
    let infoLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.chatMedium.withTraits([.traitItalic])
        label.textColor = .chatGray
        label.isHidden = true
        return label
    }()

    private(set) lazy var messageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [messageContainerView, infoLabel, nameAndDateStackView, bottomPaddingView])
        stackView.axis = .vertical
        stackView.spacing = .messageSpacing
        return stackView
    }()
    
    let messageContainerView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.isHidden = true
        return imageView
    }()
    
    private(set) lazy var messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.preferredMaxLayoutWidth = maxMessageWidth
        label.numberOfLines = 0
        return label
    }()
    
    lazy var attachmentPreviews: [AttachmentPreviewProtocol] = []
    
    private let bottomPaddingView: UIView = {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.snp.makeConstraints { $0.height.equalTo(CGFloat.messageBottomPadding).priority(999) }
        return view
    }()
    
    private var messagePadding: CGFloat {
        return .messageEdgePadding + .messageAvatarSize + .messageInnerPadding
    }
    
    var maxMessageWidth: CGFloat {
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
        
        messageLabel.backgroundColor = style.backgroundColor
        messageLabel.textColor = style.textColor
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
            make.left.equalToSuperview().offset(messagePadding).priority(999)
            make.right.equalToSuperview().offset(-messagePadding).priority(999)
        }
        
        // Reactions.
        messageContainerView.addSubview(reactionsContainer)
        reactionsContainer.addSubview(reactionsTailImage)
        reactionsContainer.addSubview(reactionsLabel)
        reactionsContainer.backgroundColor = style.reactionViewStyle.backgroundColor
        reactionsContainer.layer.cornerRadius = .reactionsCornerRadius
        reactionsTailImage.image = style.reactionViewStyle.tailImage
        reactionsTailImage.tintColor = style.reactionViewStyle.backgroundColor
        let tailAdditionalOffset: CGFloat = 2

        reactionsContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(CGFloat.reactionsHeight).priority(999)
            let minWidth = style.reactionViewStyle.tailImage.size.width + .reactionsHeight - 2 * tailAdditionalOffset
            make.width.greaterThanOrEqualTo(minWidth)

            if style.reactionViewStyle.alignment == .left {
                make.left.equalTo(messageContainerView.snp.right)
            } else {
                make.right.equalTo(messageContainerView.snp.left)
            }
        }
        
        reactionsTailImage.snp.makeConstraints { make in
            make.top.equalTo(reactionsContainer.snp.bottom)
            
            if style.alignment == .left {
                make.right.equalToSuperview().offset(tailAdditionalOffset - .reactionsCornerRadius)
            } else {
                make.left.equalToSuperview().offset(.reactionsCornerRadius - tailAdditionalOffset)
            }
        }
        
        reactionsLabel.font = style.reactionViewStyle.font
        reactionsLabel.textColor = style.reactionViewStyle.textColor
        reactionsLabel.text = "👍😄😂😛😍😎6"
        
        reactionsLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(CGFloat.reactionsTextPagging)
            make.right.equalToSuperview().offset(-CGFloat.reactionsTextPagging)
        }
        
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
        messageLabel.attributedText = nil
        messageLabel.font = style?.font
        messageLabel.backgroundColor = style?.backgroundColor
        
        paddingType = .regular
        
        free()
    }
    
    public func free() {
        attachmentPreviews.forEach { $0.removeFromSuperview() }
        attachmentPreviews = []
    }
}

public enum MessageTableViewCellPaddingType: String {
    case regular
    case small
}
