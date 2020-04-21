//
//  MessageViewStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 08/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A message view style.
public struct MessageViewStyle: Hashable {
    
    /// An alignment of a message for incoming or outgoing messages.
    public enum Alignment: String {
        /// A message view style alignment.
        case left, right
    }
    
    /// Additional date style will work with `showTimeThreshold` paramenter.
    public enum AdditionalDateStyle {
        /// Show additional date as a default style for the last message.
        case userNameAndDate
        /// Show additional date near a message without user name.
        case messageAndDate
    }
    
    /// An alignment of a message for incoming or outgoing messages.
    public var alignment: Alignment
    /// Avatars style.
    public var avatarViewStyle: AvatarViewStyle?
    /// A message font.
    public var font: UIFont
    /// A reply info font.
    public var replyFont: UIFont
    /// A user name font.
    public var nameFont: UIFont
    /// An info font, e.g. date.
    public var infoFont: UIFont
    /// An emoji font of messages.
    public var emojiFont: UIFont
    /// A message text color.
    public var textColor: UIColor
    /// A reply info text color.
    public var replyColor: UIColor
    /// An info text color, e.g. date.
    public var infoColor: UIColor
    /// A border color.
    public var borderColor: UIColor
    /// Show a time for each message with a threshold. Disabled by default.
    /// It should be more then 60 seconds between messages to make it works.
    public var showTimeThreshold: TimeInterval
    /// An additional date style (see `AdditionalDateStyle`).
    public var additionalDateStyle: AdditionalDateStyle
    
    /// A background color of the chat screen.
    public var chatBackgroundColor: UIColor {
        didSet { updateBackgroundImages() }
    }
    
    /// A background color of a message.
    public var backgroundColor: UIColor {
        didSet { updateBackgroundImages() }
    }
    
    /// A border width.
    public var borderWidth: CGFloat {
        didSet { updateBackgroundImages() }
    }
    
    /// A corner radius.
    public var cornerRadius: CGFloat {
        didSet { updateBackgroundImages() }
    }
    
    /// A corner radius.
    public var pointedCornerRadius: CGFloat {
        didSet { updateBackgroundImages() }
    }
    
    // Spacings between elements.
    public var spacing: Spacing
    /// A margin.
    public var edgeInsets: UIEdgeInsets
    
    /// A reaction style.
    public var reactionViewStyle: ReactionViewStyle
    
    /// Shows markdown text with text attributes.
    ///
    /// For example: makes italic text for "*italic*", bold text for "**bold**".
    public var markdownEnabled: Bool
    
    private(set) var backgroundImages: [UIRectCorner: BackgroundImage] = [:]
    private(set) var transparentBackgroundImages: [UIRectCorner: BackgroundImage] = [:]
    
    /// Check if the message has a generated background bubble image.
    public var hasBackgroundImage: Bool {
        (cornerRadius > 1 || pointedCornerRadius > 1) && (chatBackgroundColor != backgroundColor || borderWidth > 0)
    }
    
    /// A margin left or right offset with avatar size.
    public var marginWithAvatarOffset: CGFloat {
        guard let avatarViewStyle = avatarViewStyle else {
            return alignment == .left ? edgeInsets.left : edgeInsets.right
        }
        
        return (alignment == .left ? edgeInsets.left : edgeInsets.right) + avatarViewStyle.size + spacing.horizontal
    }
    
    /// Init a message view style.
    /// - Parameters:
    ///   - alignment: an alignment of a message for incoming or outgoing messages.
    ///   - avatarViewStyle: avatars style.
    ///   - chatBackgroundColor: a background color of the chat screen.
    ///   - font: a message font.
    ///   - replyFont: a reply info font.
    ///   - nameFont: a user name font.
    ///   - infoFont: an info font, e.g. date and time.
    ///   - emojiFont: an emoji font of messages.
    ///   - textColor: a message text color.
    ///   - replyColor: a reply info text color.
    ///   - infoColor: an info text color, e.g. date.
    ///   - backgroundColor: a background color of a message.
    ///   - borderColor: a border color.
    ///   - borderWidth: a border width.
    ///   - cornerRadius: a corner radius.
    ///   - pointedCornerRadius: a pointed corner radius.
    ///   - spacing: spacings between elements.
    ///   - edgeInsets: edge insets.
    ///   - reactionViewStyle: a reaction style.
    ///   - showTimeThreshold: a time threshold between messages to show additional time. To enable it should be more than 60 sec.
    ///   - additionalDateStyle: additional date style will work with showTimeThreshold paramenter.
    ///   - markdownEnabled: shows markdown text with text attributes, e.g. *italic*, **bold**.
    public init(alignment: Alignment = .left,
                avatarViewStyle: AvatarViewStyle? = .init(),
                chatBackgroundColor: UIColor = .white,
                font: UIFont = .chatRegular,
                replyFont: UIFont = .chatSmallBold,
                nameFont: UIFont = .chatSmallBold,
                infoFont: UIFont = .chatSmall,
                emojiFont: UIFont = .chatEmoji,
                textColor: UIColor = .black,
                replyColor: UIColor = .chatBlue,
                infoColor: UIColor = .chatGray,
                backgroundColor: UIColor = .white,
                borderColor: UIColor = .chatSuperLightGray,
                borderWidth: CGFloat = 1,
                cornerRadius: CGFloat = .messageCornerRadius,
                pointedCornerRadius: CGFloat = 0,
                spacing: Spacing = .init(horizontal: .messageInnerPadding, vertical: .messageSpacing),
                edgeInsets: UIEdgeInsets = .init(top: .messageSpacing,
                                                 left: .messageEdgePadding,
                                                 bottom: .messageBottomPadding,
                                                 right: .messageEdgePadding),
                reactionViewStyle: ReactionViewStyle = ReactionViewStyle(),
                showTimeThreshold: TimeInterval = 0,
                additionalDateStyle: AdditionalDateStyle = .userNameAndDate,
                markdownEnabled: Bool = true) {
        self.alignment = alignment
        self.avatarViewStyle = avatarViewStyle
        self.chatBackgroundColor = chatBackgroundColor
        self.font = font
        self.replyFont = replyFont
        self.nameFont = nameFont
        self.infoFont = infoFont
        self.emojiFont = emojiFont
        self.textColor = textColor
        self.replyColor = replyColor
        self.infoColor = infoColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius > 1 ? cornerRadius : 0
        self.pointedCornerRadius = pointedCornerRadius > 1 ? pointedCornerRadius : 0
        self.spacing = spacing
        self.edgeInsets = edgeInsets
        self.reactionViewStyle = reactionViewStyle
        self.showTimeThreshold = showTimeThreshold
        self.additionalDateStyle = additionalDateStyle
        self.markdownEnabled = markdownEnabled
        backgroundImages = [:]
        transparentBackgroundImages = [:]
        updateBackgroundImages()
    }
    
    private mutating func updateBackgroundImages() {
        guard hasBackgroundImage else {
            return
        }
        
        backgroundImages = [.pointedLeftBottom: BackgroundImage(cornerRadius: cornerRadius,
                                                                pointedCornerRadius: pointedCornerRadius,
                                                                corners: .pointedLeftBottom,
                                                                color: backgroundColor,
                                                                backgroundColor: chatBackgroundColor,
                                                                borderWidth: borderWidth,
                                                                borderColor: borderColor),
                            .leftSide: BackgroundImage(cornerRadius: cornerRadius,
                                                       pointedCornerRadius: pointedCornerRadius,
                                                       corners: .leftSide,
                                                       color: backgroundColor,
                                                       backgroundColor: chatBackgroundColor,
                                                       borderWidth: borderWidth,
                                                       borderColor: borderColor),
                            .pointedRightBottom: BackgroundImage(cornerRadius: cornerRadius,
                                                                 pointedCornerRadius: pointedCornerRadius,
                                                                 corners: .pointedRightBottom,
                                                                 color: backgroundColor,
                                                                 backgroundColor: chatBackgroundColor,
                                                                 borderWidth: borderWidth,
                                                                 borderColor: borderColor),
                            .rightSide: BackgroundImage(cornerRadius: cornerRadius,
                                                        pointedCornerRadius: pointedCornerRadius,
                                                        corners: .rightSide,
                                                        color: backgroundColor,
                                                        backgroundColor: chatBackgroundColor,
                                                        borderWidth: borderWidth,
                                                        borderColor: borderColor)]
        
        transparentBackgroundImages = [.pointedLeftBottom: BackgroundImage(cornerRadius: cornerRadius,
                                                                           pointedCornerRadius: pointedCornerRadius,
                                                                           corners: .pointedLeftBottom,
                                                                           color: backgroundColor,
                                                                           borderWidth: borderWidth,
                                                                           borderColor: borderColor),
                                       .leftSide: BackgroundImage(cornerRadius: cornerRadius,
                                                                  pointedCornerRadius: pointedCornerRadius,
                                                                  corners: .leftSide,
                                                                  color: backgroundColor,
                                                                  borderWidth: borderWidth,
                                                                  borderColor: borderColor),
                                       .pointedRightBottom: BackgroundImage(cornerRadius: cornerRadius,
                                                                            pointedCornerRadius: pointedCornerRadius,
                                                                            corners: .pointedRightBottom,
                                                                            color: backgroundColor,
                                                                            borderWidth: borderWidth,
                                                                            borderColor: borderColor),
                                       .rightSide: BackgroundImage(cornerRadius: cornerRadius,
                                                                   pointedCornerRadius: pointedCornerRadius,
                                                                   corners: .rightSide,
                                                                   color: backgroundColor,
                                                                   borderWidth: borderWidth,
                                                                   borderColor: borderColor)]
    }
    
    // MARK: - Hashable
    
    public static func == (lhs: MessageViewStyle, rhs: MessageViewStyle) -> Bool {
        lhs.alignment == rhs.alignment
            && lhs.avatarViewStyle == rhs.avatarViewStyle
            && lhs.chatBackgroundColor == rhs.chatBackgroundColor
            && lhs.font == rhs.font
            && lhs.replyFont == rhs.replyFont
            && lhs.nameFont == rhs.nameFont
            && lhs.infoFont == rhs.infoFont
            && lhs.emojiFont == rhs.emojiFont
            && lhs.textColor == rhs.textColor
            && lhs.replyColor == rhs.replyColor
            && lhs.infoColor == rhs.infoColor
            && lhs.backgroundColor == rhs.backgroundColor
            && lhs.borderColor == rhs.borderColor
            && lhs.borderWidth == rhs.borderWidth
            && lhs.cornerRadius == rhs.cornerRadius
            && lhs.pointedCornerRadius == rhs.pointedCornerRadius
            && lhs.spacing == rhs.spacing
            && lhs.edgeInsets == rhs.edgeInsets
            && lhs.reactionViewStyle == rhs.reactionViewStyle
            && lhs.showTimeThreshold == rhs.showTimeThreshold
            && lhs.additionalDateStyle == rhs.additionalDateStyle
            && lhs.markdownEnabled == rhs.markdownEnabled
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(alignment)
        hasher.combine(avatarViewStyle)
        hasher.combine(chatBackgroundColor)
        hasher.combine(font)
        hasher.combine(replyFont)
        hasher.combine(nameFont)
        hasher.combine(infoFont)
        hasher.combine(emojiFont)
        hasher.combine(textColor)
        hasher.combine(replyColor)
        hasher.combine(infoColor)
        hasher.combine(backgroundColor)
        hasher.combine(borderColor)
        hasher.combine(borderWidth)
        hasher.combine(cornerRadius)
        hasher.combine(pointedCornerRadius)
        hasher.combine(spacing)
        hasher.combine(edgeInsets.top)
        hasher.combine(edgeInsets.bottom)
        hasher.combine(edgeInsets.left)
        hasher.combine(edgeInsets.right)
        hasher.combine(reactionViewStyle)
        hasher.combine(showTimeThreshold)
        hasher.combine(additionalDateStyle)
        hasher.combine(markdownEnabled)
    }
}

extension MessageViewStyle {
    struct BackgroundImage {
        private let images: [Int: UIImage]
        private let defaultImage: UIImage?
        
        init(cornerRadius: CGFloat,
             pointedCornerRadius: CGFloat,
             corners: UIRectCorner,
             color: UIColor,
             backgroundColor: UIColor = .clear,
             borderWidth: CGFloat = 0,
             borderColor: UIColor = .black) {
            if #available(iOS 13, *) {
                let lightTrait = UITraitCollection(userInterfaceStyle: .light)
                let darkTrait = UITraitCollection(userInterfaceStyle: .dark)
                let lightColor = color.resolvedColor(with: lightTrait)
                let darkColor = color.resolvedColor(with: darkTrait)
                let lightBackgroundColor = backgroundColor.resolvedColor(with: lightTrait)
                let darkBackgroundColor = backgroundColor.resolvedColor(with: darkTrait)
                let lightBorderColor = borderColor.resolvedColor(with: lightTrait)
                let darkBorderColor = borderColor.resolvedColor(with: darkTrait)
                
                if lightColor != darkColor || lightBackgroundColor != darkBackgroundColor || lightBorderColor != darkBorderColor {
                    defaultImage = nil
                    
                    images = [UIUserInterfaceStyle.light.rawValue: .renderRounded(cornerRadius: cornerRadius,
                                                                                  pointedCornerRadius: pointedCornerRadius,
                                                                                  corners: corners,
                                                                                  color: lightColor,
                                                                                  backgroundColor: lightBackgroundColor,
                                                                                  borderWidth: borderWidth,
                                                                                  borderColor: lightBorderColor),
                              
                              UIUserInterfaceStyle.dark.rawValue: .renderRounded(cornerRadius: cornerRadius,
                                                                                 pointedCornerRadius: pointedCornerRadius,
                                                                                 corners: corners,
                                                                                 color: darkColor,
                                                                                 backgroundColor: darkBackgroundColor,
                                                                                 borderWidth: borderWidth,
                                                                                 borderColor: darkBorderColor)]
                    
                    return
                }
            }
            
            images = [:]
            
            defaultImage = .renderRounded(cornerRadius: cornerRadius,
                                   pointedCornerRadius: pointedCornerRadius,
                                   corners: corners,
                                   color: color,
                                   backgroundColor: backgroundColor,
                                   borderWidth: borderWidth,
                                   borderColor: borderColor)
        }
        
        func image(for traitCollection: UITraitCollection) -> UIImage? {
            guard #available(iOS 13, *), !images.isEmpty else {
                return defaultImage
            }
            
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return images[UIUserInterfaceStyle.dark.rawValue]
            default:
                return images[UIUserInterfaceStyle.light.rawValue]
            }
            
        }
    }
}
