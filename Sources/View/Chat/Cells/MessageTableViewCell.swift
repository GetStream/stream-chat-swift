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
        
        messageLabel.attributedText = attributedText()
        
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
            make.left.equalToSuperview().offset(messagePadding).priority(999)
            make.right.equalToSuperview().offset(-messagePadding).priority(999)
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
        messageLabel.attributedText = attributedText()
        
        paddingType = .regular
        
        free()
    }
    
    public func free() {
        attachmentPreviews.forEach { $0.removeFromSuperview() }
        attachmentPreviews = []
    }
    
    func attributedText(text: String? = nil, font: UIFont? = nil, backgroundColor: UIColor? = nil) -> NSAttributedString {
        let text = text ?? ""
        
        guard let style = style else {
            return NSAttributedString(string: text)
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.1
        
        return NSAttributedString(string: text, attributes: [.foregroundColor: style.textColor,
                                                             .backgroundColor: backgroundColor ?? style.backgroundColor,
                                                             .font: font ?? style.font,
                                                             .paragraphStyle: paragraphStyle])
    }
}

public enum MessageTableViewCellPaddingType: String {
    case regular
    case small
}
