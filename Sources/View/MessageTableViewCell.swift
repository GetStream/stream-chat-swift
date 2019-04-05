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
    
    private lazy var messageContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.layer.cornerRadius = .messageCornerRadius
        view.layer.borderColor = UIColor.chatBackground.cgColor
        view.layer.borderWidth = 1
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
    
    public var isIncomeMessage: Bool = true {
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
            
            if let avatarViewRightConstraint = avatarViewRightConstraint, let avatarViewLeftConstraint = avatarViewLeftConstraint {
                if isIncomeMessage {
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
    
    public func reset() {
        avatarView.image = nil
        avatarView.backgroundColor = .white
        avatarLabel.text = nil
        avatarLabel.isHidden = true
        bottomStackView.isHidden = true
        messageContainerView.isHidden = true
        dateLabel.text = nil
        messageLabel.text = nil
        paddingType = .regular
        isIncomeMessage = true
    }
    
    public func update(name: String, date: Date) {
        bottomStackView.isHidden = false
        nameLabel.text = name
        dateLabel.text = date.relative
    }
    
    public func update(message: String) {
        messageContainerView.isHidden = false
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
        
        let hue: CGFloat = abs(((CGFloat(name.hashValue) / CGFloat(Int.max)) * 15) / 15)
        avatarView.backgroundColor = .transparent(hue: hue)
        avatarLabel.isHidden = false
        avatarLabel.textColor = avatarView.backgroundColor?.withAlphaComponent(0.3)
    }
}

public enum MessageTableViewCellPaddingType: String {
    case regular
    case small
}
