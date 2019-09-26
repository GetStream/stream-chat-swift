//
//  ChannelViewStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A channel view style.
public struct ChannelViewStyle {
    /// A background color.
    public var backgroundColor: UIColor
    /// A separator color.
    public var separatorColor: UIColor
    /// A channel name font.
    public var nameFont: UIFont
    /// A channel name color.
    public var nameColor: UIColor
    /// A channel name font.
    public var nameUnreadFont: UIFont
    /// A channel name color.
    public var nameUnreadColor: UIColor
    /// A last message font.
    public var messageFont: UIFont
    /// A last message text color.
    public var messageColor: UIColor
    /// A last unread message font.
    public var messageUnreadFont: UIFont
    /// A last unread message text color.
    public var messageUnreadColor: UIColor
    /// A deleted message font.
    public var messageDeletedFont: UIFont
    /// A deleted message text color.
    public var messageDeletedColor: UIColor
    /// A date font.
    public var dateFont: UIFont
    /// A date text color.
    public var dateColor: UIColor
    
    /// Init a channel view style.
    ///
    /// - Parameters:
    ///   - backgroundColor: a background color.
    ///   - separatorColor: a separator color.
    ///   - nameFont: a channel name font.
    ///   - nameColor: a channel name color.
    ///   - nameUnreadFont: a channel unread name font.
    ///   - nameUnreadColor: a channel unread name color.
    ///   - messageFont: a last message font.
    ///   - messageColor: a last message text color.
    ///   - messageUnreadFont: a last unread message font.
    ///   - messageUnreadColor: a last unread message text color.
    ///   - messageDeletedFont: a deleted message font.
    ///   - messageDeletedColor: a deleted message text color.
    ///   - dateFont: a date font.
    ///   - dateColor: a date text color.
    public init(backgroundColor: UIColor = .white,
                separatorColor: UIColor = .chatSeparator,
                nameFont: UIFont = .chatXRegularMedium,
                nameColor: UIColor = .chatGray,
                nameUnreadFont: UIFont = .chatXRegularMedium,
                nameUnreadColor: UIColor = .black,
                messageFont: UIFont = .chatMedium,
                messageColor: UIColor = .chatGray,
                messageUnreadFont: UIFont = .chatMediumMedium,
                messageUnreadColor: UIColor = .black,
                messageDeletedFont: UIFont = .chatMediumItalic,
                messageDeletedColor: UIColor = .chatGray,
                dateFont: UIFont = .chatSmall,
                dateColor: UIColor = .chatGray) {
        self.backgroundColor = backgroundColor
        self.separatorColor = separatorColor
        self.nameFont = nameFont
        self.nameColor = nameColor
        self.nameUnreadFont = nameUnreadFont
        self.nameUnreadColor = nameUnreadColor
        self.messageFont = messageFont
        self.messageColor = messageColor
        self.messageUnreadFont = messageUnreadFont
        self.messageUnreadColor = messageUnreadColor
        self.messageDeletedFont = messageDeletedFont
        self.messageDeletedColor = messageDeletedColor
        self.dateFont = dateFont
        self.dateColor = dateColor
    }
}

extension ChannelViewStyle: Hashable {
    
    public static func == (lhs: ChannelViewStyle, rhs: ChannelViewStyle) -> Bool {
        return lhs.backgroundColor == rhs.backgroundColor
            && lhs.separatorColor == rhs.separatorColor
            && lhs.nameFont == rhs.nameFont
            && lhs.nameColor == rhs.nameColor
            && lhs.nameUnreadFont == rhs.nameUnreadFont
            && lhs.nameUnreadColor == rhs.nameUnreadColor
            && lhs.messageFont == rhs.messageFont
            && lhs.messageColor == rhs.messageColor
            && lhs.messageUnreadFont == rhs.messageUnreadFont
            && lhs.messageUnreadColor == rhs.messageUnreadColor
            && lhs.messageDeletedFont == rhs.messageDeletedFont
            && lhs.messageDeletedColor == rhs.messageDeletedColor
            && lhs.dateFont == rhs.dateFont
            && lhs.dateColor == rhs.dateColor
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(backgroundColor)
        hasher.combine(separatorColor)
        hasher.combine(nameFont)
        hasher.combine(nameColor)
        hasher.combine(nameUnreadFont)
        hasher.combine(nameUnreadColor)
        hasher.combine(messageFont)
        hasher.combine(messageColor)
        hasher.combine(messageUnreadFont)
        hasher.combine(messageUnreadColor)
        hasher.combine(messageDeletedFont)
        hasher.combine(messageDeletedColor)
        hasher.combine(dateFont)
        hasher.combine(dateColor)
    }
}
