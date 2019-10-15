//
//  MessageTableViewCell.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import SnapKit
import Nuke
import RxSwift

public final class MessageTableViewCell: UITableViewCell, Reusable {
    typealias ReactionAction = (_ cell: UITableViewCell, _ locationInView: CGPoint) -> Void
    typealias TapAction = (_ cell: MessageTableViewCell, _ message: Message) -> Void
    typealias AttachmentTapAction = (_ attachment: Attachment, _ at: Int, _ attachments: [Attachment]) -> Void
    typealias LongPressAction = (_ cell: MessageTableViewCell, _ message: Message) -> Void
    typealias AttachmentActionTapAction = (_ message: Message, _ button: UIButton) -> Void
    
    // MARK: - Properties
    
    /// A dispose bag for the cell.
    public private(set) var disposeBag = DisposeBag()
    
    let avatarView = AvatarView(cornerRadius: .messageAvatarRadius)
    
    let reactionsContainer: UIImageView = UIImageView(frame: .zero)
    let reactionsOverlayView = UIView(frame: .zero)
    let reactionsTailImage = UIImageView(frame: .zero)
    var reactionsTailImageLeftConstraint: Constraint?
    var reactionsTailImageRightConstraint: Constraint?
    
    let reactionsLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        return label
    }()
    
    private(set) lazy var nameAndDateStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, dateLabel])
        stackView.axis = .horizontal
        stackView.spacing = .messageSpacing
        stackView.snp.makeConstraints { $0.height.equalTo(CGFloat.messageAvatarRadius - .messageSpacing).priority(999) }
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
    
    let replyCountButton = UIButton(type: .custom)
    
    let readUsersView = ReadUsersView()
    var readUsersRightConstraint: Constraint?
    var readUsersBottomConstraint: Constraint?
    
    private(set) lazy var messageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [messageContainerView,
                                                       infoLabel,
                                                       replyCountButton,
                                                       nameAndDateStackView,
                                                       bottomPaddingView])
        stackView.axis = .vertical
        stackView.spacing = .messageSpacing
        return stackView
    }()
    
    var messageStackViewTopConstraint: Constraint?
    
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
    
    let bottomPaddingView: UIView = {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.snp.makeConstraints { $0.height.equalTo(CGFloat.messageBottomPadding - .messageSpacing).priority(999) }
        return view
    }()
    
    var paddingType: MessageTableViewCellPaddingType = .regular {
        didSet { bottomPaddingView.isHidden = paddingType == .small }
    }
    
    var style: MessageViewStyle? {
        didSet {
            if oldValue == nil, style != nil {
                setup()
            }
        }
    }
    
    public override func prepareForReuse() {
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
        
        replyCountButton.isHidden = true
        replyCountButton.titleLabel?.font = style.replyFont
        replyCountButton.titleLabel?.backgroundColor = backgroundColor
        replyCountButton.setTitleColor(style.replyColor, for: .normal)
        replyCountButton.backgroundColor = backgroundColor
        
        if style.alignment == .left {
            replyCountButton.setImage(UIImage.Icons.path, for: .normal)
        } else {
            replyCountButton.setImage(UIImage.Icons.path.flip(orientation: .upMirrored)?.template, for: .normal)
            replyCountButton.semanticContentAttribute = .forceRightToLeft
        }

        replyCountButton.tintColor = style.borderWidth > 0
            ? style.borderColor
            : (style.backgroundColor == style.chatBackgroundColor ? .chatGray : style.backgroundColor)
        
        if style.alignment == .left {
            nameLabel.font = style.nameFont
            nameLabel.textColor = style.infoColor
            nameLabel.backgroundColor = backgroundColor
        } else {
            nameLabel.isHidden = true
        }
        
        // Avatar
        if style.showCurrentUserAvatar {
            contentView.addSubview(avatarView)
            
            avatarView.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-CGFloat.messageBottomPadding)
                
                if style.alignment == .left {
                    make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
                } else {
                    make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
                }
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
            
            if style.showCurrentUserAvatar {
                make.left.equalToSuperview().offset(CGFloat.messageTextPaddingWithAvatar).priority(999)
                make.right.equalToSuperview().offset(-CGFloat.messageTextPaddingWithAvatar).priority(999)
            } else if style.reactionViewStyle.alignment == .left {
                make.left.equalToSuperview().offset(CGFloat.messageEdgePadding).priority(999)
                make.right.equalToSuperview().offset(-CGFloat.messageTextPaddingWithAvatar).priority(999)
            } else {
                make.left.equalToSuperview().offset(CGFloat.messageTextPaddingWithAvatar).priority(999)
                make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding).priority(999)
            }
        }
        
        infoLabel.backgroundColor = backgroundColor
        
        // Read Users.
        readUsersView.isHidden = true
        
        if style.alignment == .right {
            readUsersView.backgroundColor = backgroundColor
            readUsersView.countLabel.textColor = style.infoColor
            readUsersView.countLabel.font = style.infoFont
            contentView.addSubview(readUsersView)
            readUsersView.snp.makeConstraints { $0.height.equalTo(CGFloat.messageReadUsersSize) }
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
            
            let messagePadding: CGFloat = style.showCurrentUserAvatar ? .messageTextPaddingWithAvatar : .messageEdgePadding
            
            if style.reactionViewStyle.alignment == .left {
                make.left.greaterThanOrEqualToSuperview().offset(messagePadding).priority(999)
                make.right.greaterThanOrEqualTo(reactionsTailImage.snp.right)
                    .offset(CGFloat.reactionsCornerRadius - tailAdditionalOffset).priority(998)
            } else {
                make.right.lessThanOrEqualToSuperview().offset(-messagePadding).priority(999)
                make.left.lessThanOrEqualTo(reactionsTailImage.snp.left)
                    .offset(tailAdditionalOffset - .reactionsCornerRadius).priority(998)
            }
        }
        
        reactionsTailImage.snp.makeConstraints { make in
            make.top.equalTo(reactionsContainer.snp.bottom)
            make.size.equalTo(style.reactionViewStyle.tailImage.size)
        }
        
        reactionsLabel.font = style.reactionViewStyle.font
        reactionsLabel.textColor = style.reactionViewStyle.textColor
        
        reactionsLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(CGFloat.reactionsTextPadding)
            make.right.equalToSuperview().offset(-CGFloat.reactionsTextPadding)
        }
        
        reactionsOverlayView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(reactionsContainer).offset(-CGFloat.messageSpacing)
            make.right.equalTo(reactionsContainer).offset(CGFloat.messageSpacing)
            make.bottom.equalTo(reactionsTailImage)
        }
    }
    
    func reset() {
        avatarView.reset()
        avatarView.isHidden = true
        avatarView.backgroundColor = backgroundColor
        
        replyCountButton.isHidden = true
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
        messageContainerView.mask = nil
        
        messageLabel.attributedText = nil
        messageLabel.font = style?.font
        messageLabel.textColor = style?.textColor
        messageLabel.backgroundColor = style?.backgroundColor
        
        readUsersView.reset()
        readUsersRightConstraint?.deactivate()
        readUsersRightConstraint = nil
        readUsersBottomConstraint?.deactivate()
        readUsersBottomConstraint = nil
        
        paddingType = .regular
        
        reactionsContainer.isHidden = true
        reactionsOverlayView.isHidden = true
        reactionsLabel.text = nil
        reactionsTailImageLeftConstraint?.deactivate()
        reactionsTailImageLeftConstraint = nil
        reactionsTailImageRightConstraint?.deactivate()
        reactionsTailImageRightConstraint = nil
        
        free()
    }
    
    func free() {
        disposeBag = DisposeBag()
        attachmentPreviews.forEach { $0.removeFromSuperview() }
        attachmentPreviews = []
    }
    
    func updateReadUsersViewConstraints() {
        var visibleViews = messageStackView.arrangedSubviews.filter { $0.isHidden == false }
        
        guard visibleViews.count > 0 else {
            return
        }
        
        if visibleViews.last == bottomPaddingView {
            visibleViews.removeLast()
        }
        
        if visibleViews.last == nameAndDateStackView {
            visibleViews.removeLast()
        }
        
        if visibleViews.last == replyCountButton {
            visibleViews.removeLast()
        }
        
        if let view = visibleViews.last {
            readUsersView.snp.makeConstraints { make in
                self.readUsersRightConstraint = make.right.equalTo(view.snp.left).offset(-CGFloat.messageSpacing).constraint
                self.readUsersBottomConstraint = make.bottom.equalTo(view).constraint
            }
        }
    }
}

enum MessageTableViewCellPaddingType: String {
    case regular
    case small
}
