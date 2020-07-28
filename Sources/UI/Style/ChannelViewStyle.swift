//
//  ChannelViewStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A channel view style.
public struct ChannelViewStyle: Hashable {
    /// A background color.
    public var backgroundColor: UIColor
    /// A separator style.
    public var separatorStyle: SeparatorStyle
    /// Avatars style.
    public var avatarViewStyle: AvatarViewStyle?
    /// A name number of lines.
    public var nameNumberOfLines: Int
    /// A channel name font.
    public var nameFont: UIFont
    /// A channel name color.
    public var nameColor: UIColor
    /// A channel name font.
    public var nameUnreadFont: UIFont
    /// A channel name color.
    public var nameUnreadColor: UIColor
    /// A message number of lines.
    public var messageNumberOfLines: Int
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
    /// A name and message vertical alignment.
    public var verticalTextAlignment: VerticalAlignment
    /// A date font.
    public var dateFont: UIFont
    /// A date text color.
    public var dateColor: UIColor
    /// A channel cell height.
    public var height: CGFloat
    /// Spacings between elements.
    public var spacing: Spacing
    /// A margin.
    public var edgeInsets: UIEdgeInsets
    
    /// Init a channel view style.
    ///
    /// - Parameters:
    ///   - backgroundColor: a background color.
    ///   - separatorStyle: a separator color.
    ///   - avatarViewStyle: an avatar style.
    ///   - nameNumberOfLines: a name number of lines (default 1).
    ///   - nameFont: a channel name font.
    ///   - nameColor: a channel name color.
    ///   - nameUnreadFont: a channel unread name font.
    ///   - nameUnreadColor: a channel unread name color.
    ///   - messageNumberOfLines: a message number of lines (default 1).
    ///   - messageFont: a last message font.
    ///   - messageColor: a last message text color.
    ///   - messageUnreadFont: a last unread message font.
    ///   - messageUnreadColor: a last unread message text color.
    ///   - messageDeletedFont: a deleted message font.
    ///   - messageDeletedColor: a deleted message text color.
    ///   - dateFont: a date font.
    ///   - dateColor: a date text color.
    ///   - height: a height of a channel cell (default .automaticDimension).
    ///             If nameNumberOfLines = 1, messageNumberOfLines = 1, avatarSize > 0
    ///             then height = avatarSize + top and bottom edges.
    ///   - spacing: a spacing between elements.
    ///   - edgeInsets: edge insets.
    public init(backgroundColor: UIColor = .white,
                separatorStyle: SeparatorStyle = .none,
                avatarViewStyle: AvatarViewStyle? = .init(),
                nameNumberOfLines: Int = 1,
                nameFont: UIFont = .chatXRegularMedium,
                nameColor: UIColor = .chatGray,
                nameUnreadFont: UIFont = .chatXRegularMedium,
                nameUnreadColor: UIColor = .black,
                messageNumberOfLines: Int = 1,
                messageFont: UIFont = .chatMedium,
                messageColor: UIColor = .chatGray,
                messageUnreadFont: UIFont = .chatMediumMedium,
                messageUnreadColor: UIColor = .black,
                messageDeletedFont: UIFont = .chatMediumItalic,
                messageDeletedColor: UIColor = .chatGray,
                verticalTextAlignment: VerticalAlignment = .center,
                dateFont: UIFont = .chatSmall,
                dateColor: UIColor = .chatGray,
                height: CGFloat = UITableView.automaticDimension,
                spacing: Spacing = .init(horizontal: .messageInnerPadding, vertical: 0),
                edgeInsets: UIEdgeInsets = .init(top: .messageInnerPadding,
                                                 left: .messageEdgePadding,
                                                 bottom: .messageInnerPadding,
                                                 right: .messageEdgePadding)) {
        self.backgroundColor = backgroundColor
        self.separatorStyle = separatorStyle
        self.avatarViewStyle = avatarViewStyle
        self.nameNumberOfLines = nameNumberOfLines
        self.nameFont = nameFont
        self.nameColor = nameColor
        self.nameUnreadFont = nameUnreadFont
        self.nameUnreadColor = nameUnreadColor
        self.messageNumberOfLines = messageNumberOfLines
        self.messageFont = messageFont
        self.messageColor = messageColor
        self.messageUnreadFont = messageUnreadFont
        self.messageUnreadColor = messageUnreadColor
        self.messageDeletedFont = messageDeletedFont
        self.messageDeletedColor = messageDeletedColor
        self.verticalTextAlignment = avatarViewStyle == nil ? .top : verticalTextAlignment
        self.dateFont = dateFont
        self.dateColor = dateColor
        self.spacing = spacing
        self.edgeInsets = edgeInsets
        
        self.height = nameNumberOfLines == 1 && messageNumberOfLines == 1 && height == UITableView.automaticDimension
            ? (avatarViewStyle?.size ?? (1.5 * (nameFont.pointSize + messageFont.pointSize) + spacing.vertical))
                + edgeInsets.top
                + edgeInsets.bottom
            : height
    }
}
