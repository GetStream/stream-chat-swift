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
    
    private var avatarViewLeftConstraint: Constraint?
    private var avatarViewRightConstraint: Constraint?
    private var messageStackViewLeftConstraint: Constraint?
    private var messageStackViewRightConstraint: Constraint?
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
    
    private lazy var avatarLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatAvatar
        label.textAlignment = .center
        label.isHidden = true
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var bottomStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, dateLabel])
        stackView.axis = .horizontal
        stackView.spacing = .messageBottomSmallPadding
        stackView.isUserInteractionEnabled = false
        stackView.snp.makeConstraints { $0.height.equalTo(CGFloat.messageAvatarRadius) }
        return stackView
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatMediumSmall
        label.textColor = .chatGray
        label.backgroundColor = backgroundColor
        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        label.backgroundColor = backgroundColor
        return label
    }()
    
    private lazy var messageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [messageContainerView, bottomStackView])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = .messageBottomSmallPadding
        return stackView
    }()
    
    private lazy var messageContainerView: MessageContainerView = {
        let view = MessageContainerView(frame: .zero)
        view.backgroundColor = .white
        view.isUserInteractionEnabled = false
        return view
    }()
    
    public private(set) lazy var messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.backgroundColor = messageContainerView.backgroundColor
        label.font = .chatRegular
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        label.backgroundColor = .messageErrorBackground
        label.isHidden = true
        return label
    }()
    
    private lazy var bottomPaddingView: UIView = {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = backgroundColor
        return view
    }()
    
    public var paddingType: MessageTableViewCellPaddingType = .regular {
        didSet {
            if let bottomPadding = bottomConstraint {
                let offset: CGFloat = paddingType == paddingType ? .messageBottomRegularPadding : .messageBottomSmallPadding
                bottomPadding.update(offset: offset)
            }
        }
    }
    
    public var isIncomingMessage: Bool = true {
        didSet {
            if avatarViewRightConstraint == nil {
                avatarViewRightConstraint?.deactivate()
                
                avatarView.snp.makeConstraints { make in
                    avatarViewRightConstraint = make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding).constraint
                }
            }
            
            if messageStackViewRightConstraint == nil {
                messageStackView.alignment = .trailing
                messageStackViewLeftConstraint?.deactivate()
                let messageLeft = messageStackViewLeftConstraint?.layoutConstraints.first?.constant ?? 0
                
                messageStackView.snp.makeConstraints { make in
                    messageStackViewRightConstraint = make.right.equalToSuperview().offset(-messageLeft).constraint
                }
            }
            
            nameLabel.isHidden = !isIncomingMessage || (nameLabel.text == nil)
            messageContainerView.layerMask?.type = isIncomingMessage ? .leftCornerZero : .rightCornerZero
            
            if let avatarViewRightConstraint = avatarViewRightConstraint, let avatarViewLeftConstraint = avatarViewLeftConstraint {
                if isIncomingMessage {
                    if avatarViewRightConstraint.isActive {
                        avatarViewRightConstraint.deactivate()
                        avatarViewLeftConstraint.activate()
                        messageStackViewRightConstraint?.deactivate()
                        messageStackViewLeftConstraint?.activate()
                        messageStackView.alignment = .leading
                    }
                } else if avatarViewLeftConstraint.isActive {
                    avatarViewLeftConstraint.deactivate()
                    avatarViewRightConstraint.activate()
                    messageStackViewLeftConstraint?.deactivate()
                    messageStackViewRightConstraint?.activate()
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
            bottomConstraint = make.height.equalTo(CGFloat.messageBottomRegularPadding).constraint
        }
        
        // Avatar
        addSubview(avatarView)
        
        avatarView.snp.makeConstraints { make in
            make.bottom.equalTo(bottomPaddingView.snp.top)
            avatarViewLeftConstraint = make.left.equalToSuperview().offset(CGFloat.messageEdgePadding).constraint
        }
        
        // Message Stack View
        let messageLeft: CGFloat = .messageEdgePadding + .messageAvatarSize + .messageInnerPadding

        messageContainerView.snp.makeConstraints { make in
            let minHeight: CGFloat = 2 * .messageCornerRadius
            make.height.greaterThanOrEqualTo(minHeight)
            let maxWidth = UIScreen.main.bounds.width - 2 * messageLeft
            make.width.lessThanOrEqualTo(maxWidth)
            make.width.greaterThanOrEqualTo(minHeight)
        }
        
        messageContainerView.addSubview(messageLabel)
        
        messageLabel.snp.makeConstraints { make in
            make.left.equalTo(CGFloat.messageHorizontalInset)
            make.right.equalTo(-CGFloat.messageHorizontalInset)
            make.top.equalTo(CGFloat.messageVerticalInset)
            make.bottom.equalTo(-CGFloat.messageVerticalInset)
        }
        
        addSubview(messageStackView)
        
        messageStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.messageBottomSmallPadding)
            make.bottom.equalTo(bottomPaddingView.snp.top)
            messageStackViewLeftConstraint = make.left.equalToSuperview().offset(messageLeft).constraint
        }
    }
    
    public func reset() {
        avatarView.image = nil
        avatarView.backgroundColor = .white
        avatarLabel.text = nil
        avatarLabel.isHidden = true
        bottomStackView.isHidden = true
        messageContainerView.isHidden = true
        nameLabel.text = nil
        nameLabel.isHidden = true
        dateLabel.text = nil
        messageLabel.text = nil
        paddingType = .regular
        isIncomingMessage = true
    }
    
    public func update(style: ChatViewStyle.Message) {
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
        messageContainerView.backgroundColor = style.backgroundColor
        let cornerType: MessageLayerMaskType = isIncomingMessage ? .leftCornerZero : .rightCornerZero
        messageContainerView.update(cornerRadius: style.cornerRadius, type: cornerType)
        messageContainerView.update(borderWidth: style.borderWidth, color: style.borderColor)
    }
    
    public func update(name: String?, date: Date) {
        bottomStackView.isHidden = false
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
    
    private func showAvatarLabel(with name: String) {
        if name.contains(" ") {
            let words = name.split(separator: " ")
            
            if let a = String(describing: words[0]).first, let b = String(describing: words[1]).first {
                avatarLabel.text = String(a).appending(String(b)).uppercased()
            }
        } else {
            avatarLabel.text = name.first?.uppercased()
        }
        
        var brightness: CGFloat = 0.5
        
        if let backgroundColor = backgroundColor {
            brightness = backgroundColor.isDark ? 1 : 0.5
        }
        
        let hue: CGFloat = abs(((CGFloat(name.hashValue) / CGFloat(Int.max)) * 15) / 15)
        avatarView.backgroundColor = .transparent(hue: hue, brightness: brightness)
        avatarLabel.isHidden = false
        avatarLabel.textColor = avatarView.backgroundColor?.withAlphaComponent(0.3)
    }
}

public enum MessageTableViewCellPaddingType: String {
    case regular
    case small
}
