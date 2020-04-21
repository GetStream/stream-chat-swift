//
//  ChannelTableViewCell.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift

/// Channel table view cell.
open class ChannelTableViewCell: UITableViewCell, Reusable {
    
    /// A channel style.
    public var style: ChannelViewStyle = ChannelViewStyle()
    /// Checks if needds setup layout.
    public private(set) var needsToSetup = true
    
    /// An avatar view.
    public private(set) lazy var avatarView = AvatarView(cornerRadius: style.avatarViewStyle?.radius ?? .channelAvatarRadius,
                                                         font: style.avatarViewStyle?.placeholderFont)
    
    /// A dispose bag for the cell.
    public private(set) var disposeBag = DisposeBag()
    
    /// A channel name label.
    public let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatRegularBold
        return label
    }()
    
    /// A last message label.
    public let messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatMedium
        return label
    }()
    
    /// A date label.
    public let dateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        return label
    }()
    
    /// An info label.
    private let infoLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        return label
    }()
    
    override open func prepareForReuse() {
        reset()
        super.prepareForReuse()
    }
    
    /// Setup style and layouts.
    /// - Parameter style: a message view style.
    public func setupIfNeeded(style: ChannelViewStyle) {
        guard needsToSetup else {
            return
        }
        
        needsToSetup = false
        self.style = style
        selectionStyle = .none
        backgroundColor = style.backgroundColor
        
        nameLabel.font = style.nameFont
        nameLabel.textColor = style.nameColor
        nameLabel.backgroundColor = backgroundColor
        nameLabel.numberOfLines = style.nameNumberOfLines
        
        messageLabel.font = style.messageFont
        messageLabel.textColor = style.messageColor
        messageLabel.backgroundColor = backgroundColor
        messageLabel.numberOfLines = style.messageNumberOfLines
        
        dateLabel.font = style.dateFont
        dateLabel.textColor = style.dateColor
        dateLabel.backgroundColor = backgroundColor
        
        infoLabel.font = style.dateFont
        infoLabel.textColor = style.dateColor
        infoLabel.backgroundColor = backgroundColor
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(infoLabel)
        var hasAvatar = false
        
        if let avatarViewStyle = style.avatarViewStyle {
            hasAvatar = true
            contentView.addSubview(avatarView)
            
            avatarView.backgroundColor = backgroundColor
            avatarView.snp.makeConstraints { make in
                if avatarViewStyle.verticalAlignment == .center {
                    make.centerY.equalToSuperview().priority(999)
                } else {
                    make.top.equalToSuperview().offset(style.edgeInsets.top).priority(999)
                }
                make.bottom.lessThanOrEqualToSuperview().offset(-style.edgeInsets.bottom).priority(999)
                make.left.equalToSuperview().offset(style.edgeInsets.left)
                make.size.equalTo(avatarViewStyle.size)
            }
        }
        
        nameLabel.snp.makeConstraints { make in
            if style.verticalTextAlignment == .center {
                make.bottom.equalTo(contentView.snp.centerY).offset(style.spacing.vertical / -2).priority(999)
                make.left.equalTo(avatarView.snp.right).offset(style.spacing.horizontal)
            } else {
                make.top.equalToSuperview().offset(style.edgeInsets.top).priority(999)
                
                if hasAvatar {
                    make.left.equalTo(avatarView.snp.right).offset(style.spacing.horizontal)
                } else {
                    make.left.equalToSuperview().offset(style.edgeInsets.left)
                }
            }
            
            make.right.lessThanOrEqualTo(dateLabel.snp.left).offset(-style.spacing.horizontal)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-style.edgeInsets.right)
            make.centerY.equalTo(nameLabel.snp.centerY)
        }
        
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        infoLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-style.edgeInsets.right)
            make.centerY.equalTo(messageLabel.snp.centerY)
        }
        
        infoLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        messageLabel.snp.makeConstraints { make in
            if style.verticalTextAlignment == .center {
                make.top.equalTo(contentView.snp.centerY).offset(style.spacing.vertical / 2).priority(999)
            } else {
                make.top.equalTo(nameLabel.snp.bottom).offset(style.spacing.vertical).priority(999)
            }
            
            make.left.equalTo(nameLabel)
            make.right.equalTo(infoLabel.snp.left).offset(-style.spacing.horizontal)
            make.bottom.lessThanOrEqualToSuperview().offset(-style.edgeInsets.bottom).priority(999)
        }
    }
    
    func reset() {
        if style.avatarViewStyle != nil {
            avatarView.reset()
        }
        
        nameLabel.text = nil
        dateLabel.text = nil
        messageLabel.text = nil
        infoLabel.text = nil
        disposeBag = DisposeBag()
    }
    
    /// Update the channel cell with a message text.
    ///
    /// - Parameters:
    ///   - message: a last message text.
    ///   - isMeta: shows the message text as a meta data.
    ///   - isUnread: shows the message as unread.
    public func update(message: String, isMeta: Bool, isUnread: Bool) {
        if isMeta {
            messageLabel.font = style.messageDeletedFont
            messageLabel.textColor = style.messageDeletedColor
            messageLabel.text = message
            return
        }
        
        if isUnread {
            nameLabel.font = style.nameUnreadFont
            nameLabel.textColor = style.nameUnreadColor
            messageLabel.font = style.messageUnreadFont
            messageLabel.textColor = style.messageUnreadColor
        } else {
            nameLabel.font = style.nameFont
            nameLabel.textColor = style.nameColor
            messageLabel.font = style.messageFont
            messageLabel.textColor = style.messageColor
        }
        
        messageLabel.text = message
    }
    
    /// Update the channel cell with an info text.
    ///
    /// - Parameters:
    ///   - info: an info text.
    ///   - isUnread: if true apply an unread view style.
    public func update(info: String?, isUnread: Bool = false) {
        guard let info = info else {
            return
        }
        
        if isUnread {
            infoLabel.font = style.messageUnreadFont
            infoLabel.textColor = style.messageUnreadColor
        } else {
            infoLabel.font = style.dateFont
            infoLabel.textColor = style.dateColor
        }
        
        infoLabel.text = info
    }
    
    /// Update the date of the cell with a given date
    ///
    /// - Parameters:
    ///  - date: Date to be written in the date label.
    open func update(date: Date) {
        dateLabel.text = date.relative
    }
}
