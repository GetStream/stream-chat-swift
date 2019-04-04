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
    
    public private(set) lazy var avatarView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.layer.cornerRadius = .messageAvatarRadius
        view.contentMode = .scaleAspectFill
        view.snp.makeConstraints { $0.width.height.equalTo(CGFloat.messageAvatarSize) }
        view.addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
        return view
    }()
    
    public private(set) lazy var avatarLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatAvatar
        label.textAlignment = .center
        label.isHidden = true
        label.isUserInteractionEnabled = false
        return label
    }()
    
    public private(set) lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatMediumSmall
        label.textColor = .chatGray
        label.backgroundColor = backgroundColor
        label.isUserInteractionEnabled = false
        return label
    }()

    public private(set) lazy var dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        label.backgroundColor = backgroundColor
        label.isUserInteractionEnabled = false
        return label
    }()
    
    public private(set) lazy var messageContainerView: UIView = {
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
    
    private var bottomConstraint: Constraint?

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
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.bottom.equalTo(bottomPaddingView.snp.top)
        }
        
        // Name & Date
        addSubview(nameLabel)
        addSubview(dateLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(CGFloat.messageInnerPadding)
            make.bottom.equalTo(bottomPaddingView.snp.top)
        }

        dateLabel.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(CGFloat.messageBottomSmallPadding)
            make.bottom.equalTo(bottomPaddingView.snp.top)
        }
        
        // Message
        addSubview(messageContainerView)
        
        messageContainerView.snp.makeConstraints { make in
            let left: CGFloat = .messageEdgePadding + .messageAvatarSize + .messageInnerPadding
            make.left.equalToSuperview().offset(left)
            make.top.equalToSuperview().offset(CGFloat.messageBottomSmallPadding)
            make.bottom.equalTo(avatarView.snp.centerY)
            let minHeight: CGFloat = 2 * .messageCornerRadius
            make.height.greaterThanOrEqualTo(minHeight)
            let maxWidth = UIScreen.main.bounds.width - 2 * left
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
    }
    
    public func reset() {
        avatarView.image = nil
        avatarView.backgroundColor = .white
        avatarLabel.text = nil
        avatarLabel.isHidden = true
        dateLabel.text = nil
        messageLabel.text = nil
        paddingType = .regular
    }
    
    public func updateAvatar(with url: URL?, name: String) {
        guard let url = url, !url.absoluteString.lowercased().contains("svg") else {
            showAvatarLabel(with: name)
            return
        }
        
        let imageSize = avatarView.bounds.width * UIScreen.main.scale
        let request = ImageRequest(url: url, targetSize: CGSize(width: imageSize, height: imageSize), contentMode: .aspectFill)
        
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
