//
//  ChannelTableViewCell.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public final class ChannelTableViewCell: UITableViewCell, Reusable {
    
    let avatarView: AvatarView = AvatarView(cornerRadius: 20)
    
    let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatRegularBold
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatMedium
        return label
    }()
    
    let dateLabel: UILabel = {
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
        
        dateLabel.font = style.dateFont
        dateLabel.textColor = style.dateColor
        dateLabel.backgroundColor = backgroundColor
        
        messageLabel.font = style.messageFont
        messageLabel.textColor = style.messageColor
        messageLabel.backgroundColor = backgroundColor
        
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(messageLabel)
        
        avatarView.backgroundColor = backgroundColor
        avatarView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(CGFloat.messageEdgePadding).priority(999)
            make.size.equalTo(CGFloat.channelBigAvatarSize)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(CGFloat.messageEdgePadding)
            make.right.lessThanOrEqualTo(dateLabel.snp.left).offset(-CGFloat.messageEdgePadding)
            make.bottom.equalTo(avatarView.snp.centerY)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.centerY.equalTo(nameLabel.snp.centerY)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView.snp.centerY)
            make.left.right.equalTo(nameLabel)
        }
    }
    
    func reset() {
        avatarView.reset()
        nameLabel.text = nil
        dateLabel.text = nil
        messageLabel.text = nil
    }
    
    func update(message: String, isDeleted: Bool, isUnread: Bool) {
        guard let style = style else {
            return
        }
        
        if isDeleted {
            messageLabel.font = style.messageDeletedFont
            messageLabel.textColor = style.messageDeletedColor
            messageLabel.text = "Message was deleted"
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
}
