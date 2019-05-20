//
//  ChannelViewStyle.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public struct ChannelViewStyle: Hashable {
    public let backgroundColor: UIColor
    public let separatorColor: UIColor
    public let nameFont: UIFont
    public let nameColor: UIColor
    public let messageFont: UIFont
    public let messageColor: UIColor
    public let messageUnreadFont: UIFont
    public let messageUnreadColor: UIColor
    public let messageDeletedFont: UIFont
    public let messageDeletedColor: UIColor
    public let dateFont: UIFont
    public let dateColor: UIColor
    
    init(backgroundColor: UIColor = .chatSuperLightGray,
         separatorColor: UIColor = .chatSeparator,
         titleFont: UIFont = .chatXRegularMedium,
         titleColor: UIColor = .black,
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
        self.nameFont = titleFont
        self.nameColor = titleColor
        self.messageFont = messageFont
        self.messageColor = messageColor
        self.messageUnreadFont = messageUnreadFont
        self.messageUnreadColor = messageUnreadColor
        self.messageDeletedFont = messageDeletedFont
        self.messageDeletedColor = messageDeletedColor
        self.dateFont = dateFont
        self.dateColor = dateColor
    }
    
    public func hash(into hasher:
        inout Hasher) {
        hasher.combine(backgroundColor)
        hasher.combine(separatorColor)
        hasher.combine(nameFont)
        hasher.combine(nameColor)
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
