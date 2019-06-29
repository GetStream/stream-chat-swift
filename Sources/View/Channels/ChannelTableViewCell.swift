//
//  ChannelTableViewCell.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public final class ChannelTableViewCell: UITableViewCell, Reusable {
    
    public let avatarView: AvatarView = AvatarView(cornerRadius: 20)
    
    public let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatRegularBold
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatMedium
        return label
    }()
    
    public let dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        return label
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        return label
    }()
    
    public var style: ChannelViewStyle? {
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
    
    func setup() {
        guard let style = style else {
            return
        }
        
        selectionStyle = .none
        backgroundColor = style.backgroundColor
        
        nameLabel.font = style.nameFont
        nameLabel.textColor = style.nameColor
        nameLabel.backgroundColor = backgroundColor

        messageLabel.font = style.messageFont
        messageLabel.textColor = style.messageColor
        messageLabel.backgroundColor = backgroundColor
        
        dateLabel.font = style.dateFont
        dateLabel.textColor = style.dateColor
        dateLabel.backgroundColor = backgroundColor
        
        infoLabel.font = style.dateFont
        infoLabel.textColor = style.dateColor
        infoLabel.backgroundColor = backgroundColor
        
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(infoLabel)

        avatarView.backgroundColor = backgroundColor
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.messageInnerPadding).priority(999)
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.size.equalTo(CGFloat.channelBigAvatarSize)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(CGFloat.messageInnerPadding)
            make.right.lessThanOrEqualTo(dateLabel.snp.left).offset(-CGFloat.messageInnerPadding)
            make.bottom.equalTo(avatarView.snp.centerY)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.centerY.equalTo(nameLabel.snp.centerY)
        }
        
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        infoLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.centerY.equalTo(messageLabel.snp.centerY)
        }
        
        infoLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.centerY)
            make.left.equalTo(nameLabel)
            make.right.equalTo(infoLabel.snp.left).offset(-CGFloat.messageInnerPadding)
        }
    }
    
    func reset() {
        avatarView.reset()
        nameLabel.text = nil
        dateLabel.text = nil
        messageLabel.text = nil
        infoLabel.text = nil
    }
    
    public func update(message: String, isMeta: Bool, isUnread: Bool) {
        guard let style = style else {
            return
        }
        
        if isMeta {
            messageLabel.font = style.messageDeletedFont
            messageLabel.textColor = style.messageDeletedColor
            messageLabel.text = message
            return
        }
        
        if isUnread {
            messageLabel.font = style.messageUnreadFont
            messageLabel.textColor = style.messageUnreadColor
        } else {
            messageLabel.font = style.messageFont
            messageLabel.textColor = style.messageColor
        }
        
        messageLabel.text = message
    }
    
    public func update(info: String?, bold: Bool = false) {
        guard let style = style, let info = info else {
            return
        }
        
        if bold {
            infoLabel.font = style.messageUnreadFont
            infoLabel.textColor = style.messageUnreadColor
        } else {
            infoLabel.font = style.dateFont
            infoLabel.textColor = style.dateColor
        }
        
        infoLabel.text = info
    }
}
