//
//  MessageTableViewCell.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import Reusable
import Nuke

final class MessageTableViewCell: UITableViewCell, Reusable {
    private static let imagePreviewHeight: CGFloat = 100
    
    private var avatarViewLeftConstraint: Constraint?
    private var avatarViewRightConstraint: Constraint?
//    private var messageStackViewLeftConstraint: Constraint?
//    private var messageStackViewRightConstraint: Constraint?
    private var bottomConstraint: Constraint?
    
    private lazy var avatarView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.layer.cornerRadius = .messageAvatarRadius
        view.contentMode = .scaleAspectFill
        view.snp.makeConstraints { $0.width.height.equalTo(CGFloat.messageAvatarSize) }
        view.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
        return view
    }()
    
    private let avatarLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatAvatar
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private lazy var nameAndDateStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, dateLabel])
        stackView.axis = .horizontal
        stackView.spacing = .messageSpacing
        stackView.snp.makeConstraints { $0.height.equalTo(CGFloat.messageAvatarRadius) }
        return stackView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatMediumSmall
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
        let stackView = UIStackView(arrangedSubviews: [attachmentImageView, messageContainerView, nameAndDateStackView])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = .messageSpacing
        return stackView
    }()
    
    private let messageContainerView = UIImageView(frame: .zero)
    
    private let messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatRegular
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    private var attachmentImageWidthConstraint: Constraint?
    
    private lazy var attachmentImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.Icons.image)
        imageView.contentMode = .center
        imageView.isHidden = true
        imageView.clipsToBounds = true
        
        imageView.snp.makeConstraints {
            $0.height.equalTo(100)
            attachmentImageWidthConstraint = $0.width.equalTo(MessageTableViewCell.imagePreviewHeight).constraint
        }
        
        return imageView
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        label.backgroundColor = .messageErrorBackground
        label.isHidden = true
        return label
    }()
    
    private let bottomPaddingView: UIView = {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private var messagePadding: CGFloat {
        return .messageEdgePadding + .messageAvatarSize + .messageInnerPadding
    }
    
    private var maxMessageWidth: CGFloat {
        return UIScreen.main.bounds.width - 2 * messagePadding
    }

    public var paddingType: MessageTableViewCellPaddingType = .regular {
        didSet {
            if let bottomPadding = bottomConstraint {
                let offset: CGFloat = paddingType == .regular ? .messageBottomPadding : 0
                bottomPadding.update(offset: offset)
            }
        }
    }
    
    public var isIncomingMessage: Bool = true {
        didSet {
            return
            if avatarViewRightConstraint == nil {
                avatarViewRightConstraint?.deactivate()
                
                avatarView.snp.makeConstraints { make in
                    avatarViewRightConstraint = make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding).constraint
                }
            }
            
//            if messageStackViewRightConstraint == nil {
//                messageStackView.alignment = .trailing
//                messageStackViewLeftConstraint?.deactivate()
//                let messageLeft = messageStackViewLeftConstraint?.layoutConstraints.first?.constant ?? 0
//
//                messageStackView.snp.makeConstraints { make in
//                    messageStackViewRightConstraint = make.right.equalToSuperview().offset(-messageLeft).constraint
//                }
//            }
            
            nameLabel.isHidden = !isIncomingMessage || (nameLabel.text == nil)
            
            if let avatarViewRightConstraint = avatarViewRightConstraint, let avatarViewLeftConstraint = avatarViewLeftConstraint {
                if isIncomingMessage {
                    if avatarViewRightConstraint.isActive {
                        avatarViewRightConstraint.deactivate()
                        avatarViewLeftConstraint.activate()
//                        messageStackViewRightConstraint?.deactivate()
//                        messageStackViewLeftConstraint?.activate()
                        messageStackView.alignment = .leading
                    }
                } else if avatarViewLeftConstraint.isActive {
                    avatarViewLeftConstraint.deactivate()
                    avatarViewRightConstraint.activate()
//                    messageStackViewLeftConstraint?.deactivate()
//                    messageStackViewRightConstraint?.activate()
                    messageStackView.alignment = .trailing
                }
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
        reset()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        reset()
    }
    
    override func prepareForReuse() {
        reset()
        super.prepareForReuse()
    }
    
    private func setup() {
        selectionStyle = .none
        backgroundColor = .white
        
        // Bottom Padding View
        addSubview(bottomPaddingView)
        
        bottomPaddingView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            bottomConstraint = make.height.equalTo(CGFloat.messageBottomPadding).constraint
        }
        
        // Avatar
        addSubview(avatarView)
        
        avatarView.snp.makeConstraints { make in
            make.bottom.equalTo(bottomPaddingView.snp.top)
            avatarViewLeftConstraint = make.left.equalToSuperview().offset(CGFloat.messageEdgePadding).constraint
        }
        
        // Message Stack View
        
//        messageContainerView.snp.makeConstraints { make in
//            let minHeight: CGFloat = 2 * .messageCornerRadius
//            make.height.greaterThanOrEqualTo(minHeight)
//            let maxWidth = UIScreen.main.bounds.width - 2 * messageLeft
//            make.width.lessThanOrEqualTo(maxWidth)
//            make.width.greaterThanOrEqualTo(minHeight)
//        }
        
        messageContainerView.addSubview(messageLabel)
        
        messageLabel.snp.makeConstraints { make in
            make.left.equalTo(CGFloat.messageHorizontalInset)
            make.right.equalTo(-CGFloat.messageHorizontalInset)
            make.top.equalTo(CGFloat.messageVerticalInset)
            make.bottom.equalTo(-CGFloat.messageVerticalInset)
        }
        
        addSubview(messageStackView)
        
        messageStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.bottom.equalTo(bottomPaddingView.snp.top)
            make.left.equalToSuperview().offset(messagePadding)
            make.right.equalToSuperview().offset(-messagePadding)
        }
    }
    
    public func reset() {
        avatarView.isHidden = true
        avatarView.image = nil
        avatarView.backgroundColor = .white
        avatarLabel.text = nil
        avatarLabel.isHidden = true
        attachmentImageView.isHidden = true
        attachmentImageView.contentMode = .center
        attachmentImageView.image = UIImage.Icons.image
        attachmentImageWidthConstraint?.update(offset: 100)
        nameAndDateStackView.isHidden = true
        messageContainerView.isHidden = true
        messageContainerView.image = nil
        messageContainerView.isOpaque = true
        messageContainerView.layer.borderWidth = 0
        nameLabel.text = nil
        nameLabel.isHidden = true
        dateLabel.text = nil
        messageLabel.text = nil
        paddingType = .regular
    }
    
    public func update(style: ChatViewStyle.Message, messageBackgroundImage: UIImage?) {
        backgroundColor = style.chatBackgroundColor
        nameLabel.font = style.infoFont
        nameLabel.textColor = style.infoColor
        nameLabel.backgroundColor = backgroundColor
        dateLabel.font = style.infoFont
        dateLabel.textColor = style.infoColor
        dateLabel.backgroundColor = backgroundColor
        bottomPaddingView.backgroundColor = backgroundColor
        
        messageLabel.font = style.font
        messageLabel.textColor = style.textColor
        messageLabel.backgroundColor = style.backgroundColor
        
        attachmentImageView.tintColor = style.textColor
        attachmentImageView.mask = nil
        attachmentImageView.layer.cornerRadius = style.cornerRadius
        
        if let messageBackgroundImage = messageBackgroundImage {
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
    
    public func update(name: String?, date: Date) {
        nameAndDateStackView.isHidden = false
        dateLabel.text = date.relative
        
        if let name = name, !name.isEmpty {
            nameLabel.text = name
            nameLabel.isHidden = !isIncomingMessage
        } else {
            nameLabel.isHidden = true
        }
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
    
    public func update(name: String, attachmentImageURL url: URL) {
        attachmentImageView.backgroundColor = colorByName(name: name)
        attachmentImageView.isHidden = false
        
        Nuke.loadImage(with: url, into: attachmentImageView) { [weak self] in
            self?.parseAttachmentImageResponse(response: $0, error: $1)
        }
    }
    
    private func parseAttachmentImageResponse(response: ImageResponse?, error: Error?) {
        var width = MessageTableViewCell.imagePreviewHeight
        
        if let image = response?.image, image.size.height > 0 {
            attachmentImageView.contentMode = .scaleAspectFit
            width = min(image.size.width / image.size.height * MessageTableViewCell.imagePreviewHeight, maxMessageWidth)
            attachmentImageWidthConstraint?.update(offset: width)
        } else {
            attachmentImageView.image = UIImage.Icons.close
            
            if let error = error {
                print("⚠️", error)
            }
        }
        
        if let maskImage = messageContainerView.image {
            let maskView = UIImageView(frame: CGRect(width: width, height: MessageTableViewCell.imagePreviewHeight))
            maskView.image = maskImage
            attachmentImageView.mask = maskView
            attachmentImageView.layer.cornerRadius = 0
        }
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
        
        avatarView.backgroundColor = colorByName(name: name)
        avatarLabel.isHidden = false
        avatarLabel.textColor = avatarView.backgroundColor?.withAlphaComponent(0.3)
    }
    
    private func colorByName(name: String) -> UIColor {
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
