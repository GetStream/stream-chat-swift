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
import RxSwift

final class MessageTableViewCell: UITableViewCell, Reusable {
    typealias ReactionAction = (_ cell: UITableViewCell) -> Void
    typealias TapAction = (_ cell: MessageTableViewCell, _ message: Message) -> Void
    typealias AttachmentTapAction = (_ attachment: Attachment, _ at: Int, _ attachments: [Attachment]) -> Void
    typealias LongPressAction = (_ cell: MessageTableViewCell, _ message: Message) -> Void
    
    static let longPressMinimumDuration: TimeInterval = 0.3
    
    // MARK: - Properties
    
    private(set) var disposeBag = DisposeBag()
    
    let avatarView = AvatarView(cornerRadius: .messageAvatarRadius)
    
    let reactionsContainer: UIImageView = UIImageView(frame: .zero)
    let reactionsOverlayView = UIView(frame: .zero)
    private let reactionsTailImage = UIImageView(frame: .zero)
    
    let reactionsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        return label
    }()
    
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
        label.font = .chatSmallBold
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
    
    private var messageStackViewTopConstraint: Constraint?
    
    let messageContainerView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.isHidden = true
        return imageView
    }()
    
    private(set) lazy var messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
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
        
        messageLabel.attributedText = nil
        messageLabel.numberOfLines = 0
        messageLabel.font = style.font
        messageLabel.textColor = style.textColor
        messageLabel.backgroundColor = style.backgroundColor
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
            messageStackViewTopConstraint = make.top.equalToSuperview().offset(CGFloat.messageSpacing).priority(999).constraint
            make.bottom.equalToSuperview().priority(999)
            make.left.equalToSuperview().offset(CGFloat.messageTextPadding).priority(999)
            make.right.equalToSuperview().offset(-CGFloat.messageTextPadding).priority(999)
        }
        
        // Reactions.
        contentView.addSubview(reactionsContainer)
        contentView.addSubview(reactionsOverlayView)
        reactionsOverlayView.isHidden = true
        reactionsContainer.isHidden = true
        reactionsContainer.addSubview(reactionsTailImage)
        reactionsContainer.addSubview(reactionsLabel)
        reactionsContainer.backgroundColor = style.reactionViewStyle.backgroundColor
        reactionsContainer.layer.cornerRadius = .reactionsCornerRadius
        reactionsTailImage.image = style.reactionViewStyle.tailImage
        reactionsTailImage.tintColor = style.reactionViewStyle.backgroundColor
        let tailAdditionalOffset: CGFloat = 2
        
        reactionsContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.messageSpacing)
            make.height.equalTo(CGFloat.reactionsHeight).priority(999)
            let minWidth = style.reactionViewStyle.tailImage.size.width + .reactionsHeight - 2 * tailAdditionalOffset
            make.width.greaterThanOrEqualTo(minWidth)
            
            if style.reactionViewStyle.alignment == .left {
                make.left.greaterThanOrEqualToSuperview().offset(CGFloat.messageTextPadding).priority(999)
                make.right.greaterThanOrEqualTo(reactionsTailImage.snp.right)
                    .offset(CGFloat.reactionsCornerRadius - tailAdditionalOffset).priority(998)
            } else {
                make.right.lessThanOrEqualToSuperview().offset(-CGFloat.messageTextPadding).priority(999)
                make.left.lessThanOrEqualTo(reactionsTailImage.snp.left)
                    .offset(tailAdditionalOffset - .reactionsCornerRadius).priority(998)
            }
        }
        
        reactionsTailImage.snp.makeConstraints { make in
            make.top.equalTo(reactionsContainer.snp.bottom)
            make.size.equalTo(style.reactionViewStyle.tailImage.size)
            
            if style.alignment == .left {
                make.left.equalTo(messageLabel.snp.right).offset(CGFloat.reactionsToMessageOffset - .messageInnerPadding)
            } else {
                make.right.equalTo(messageLabel.snp.left).offset(CGFloat.messageInnerPadding - .reactionsToMessageOffset)
            }
        }
        
        reactionsLabel.font = style.reactionViewStyle.font
        reactionsLabel.textColor = style.reactionViewStyle.textColor
        
        reactionsLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(CGFloat.reactionsTextPagging)
            make.right.equalToSuperview().offset(-CGFloat.reactionsTextPagging)
        }
        
        reactionsOverlayView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(reactionsContainer).offset(-CGFloat.messageSpacing)
            make.right.equalTo(reactionsContainer).offset(CGFloat.messageSpacing)
            make.bottom.equalTo(reactionsTailImage)
        }
    }
    
    func updateConstraintsForReactions() {
        messageStackViewTopConstraint?.update(offset: CGFloat.messageSpacing + .reactionsHeight + .reactionsToMessageOffset)
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
        
        messageStackViewTopConstraint?.update(offset: CGFloat.messageSpacing)
        
        messageContainerView.isHidden = true
        messageContainerView.image = nil
        messageContainerView.layer.borderWidth = 0
        messageContainerView.backgroundColor = style?.chatBackgroundColor
        
        messageLabel.attributedText = nil
        messageLabel.font = style?.font
        messageLabel.textColor = style?.textColor
        messageLabel.backgroundColor = style?.backgroundColor
        
        paddingType = .regular
        
        reactionsContainer.isHidden = true
        reactionsOverlayView.isHidden = true
        reactionsLabel.text = nil
        
        free()
    }
    
    public func free() {
        disposeBag = DisposeBag()
        attachmentPreviews.forEach { $0.removeFromSuperview() }
        attachmentPreviews = []
    }
}

public enum MessageTableViewCellPaddingType: String {
    case regular
    case small
}
