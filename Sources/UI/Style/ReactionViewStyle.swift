//
//  ReactionViewStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 09/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A reaction view style.
public struct ReactionViewStyle: Hashable {
    
    /// An alignment of a reaction for incoming or outgoing messages.
    public let alignment: MessageViewStyle.Alignment
    /// A font of a count of a reaction.
    public let font: UIFont
    /// A text color of a count of a reaction.
    public let textColor: UIColor
    /// A background color of reactions.
    public let backgroundColor: UIColor
    /// A background color of the chat screen.
    public let chatBackgroundColor: UIColor
    /// A corner radius of the bubble.
    public let cornerRadius: CGFloat
    /// A small corner radius of the tail to the reactions bubble.
    public let tailCornerRadius: CGFloat
    /// A corner radius of the message bubble.
    public let tailMessageCornerRadius: CGFloat
    /// A generated tail image.
    public private(set) var tailImage: UIImage
    
    /// Init a reaction view style.
    ///
    /// - Parameters:
    ///     - alignment: an alignment of the reaction for incoming or outgoing messages.
    ///     - font: a font of a count of a reaction.
    ///     - textColor: a text color of a count of a reaction.
    ///     - backgroundColor: a background color of reactions.
    ///     - chatBackgroundColor: a background color of the chat screen.
    ///     - cornerRadius: a corner radius of the bubble.
    ///     - tailMessageCornerRadius: a corner radius of the message bubble.
    public init(alignment: MessageViewStyle.Alignment = .left,
                font: UIFont = .chatSmall,
                textColor: UIColor = .white,
                backgroundColor: UIColor = .chatDarkGray,
                chatBackgroundColor: UIColor = .white,
                cornerRadius: CGFloat = .reactionsCornerRadius,
                tailMessageCornerRadius: CGFloat = .messageCornerRadius) {
        self.alignment = alignment
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.chatBackgroundColor = chatBackgroundColor
        self.cornerRadius = cornerRadius
        self.tailCornerRadius = cornerRadius * 0.8
        self.tailMessageCornerRadius = tailMessageCornerRadius
        tailImage = .renderTailImage(smallRadius: tailCornerRadius, bigRadius: tailMessageCornerRadius, alignment: alignment)
    }
}
