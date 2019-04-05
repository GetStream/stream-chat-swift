//
//  MessageViewStyle.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 05/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public struct ChatViewStyle: Hashable {
    
    public var backgroundColor: UIColor = .white
    public var incomingMessage = Message()
    
    public var outgoingMessage = Message(backgroundColor: .messageBorder,
                                         borderColor: .messageBorder,
                                         borderWidth: 0)
    
    public var errorMessage = Message(backgroundColor: .messageErrorBackground,
                                      borderColor: .messageErrorBorder)
    
    public static let dark =
        ChatViewStyle(backgroundColor: .init(white: 0.1, alpha: 1),
                      incomingMessage: Message(font: .chatSmall,
                                               infoFont: .chatSmall,
                                               textColor: .white,
                                               backgroundColor: .init(white: 0.1, alpha: 1),
                                               borderColor: .chatGray),
                      outgoingMessage: Message(font: .chatSmall,
                                               infoFont: .chatSmall,
                                               textColor: .white,
                                               backgroundColor: .init(white: 0.2, alpha: 1),
                                               borderWidth: 0),
                      errorMessage: Message(font: .chatSmall,
                                            infoFont: .chatSmall,
                                            textColor: .white,
                                            backgroundColor: .init(white: 0.1, alpha: 1),
                                            borderColor: .chatGray))
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(backgroundColor)
        hasher.combine(incomingMessage)
        hasher.combine(outgoingMessage)
        hasher.combine(errorMessage)
    }
}

extension ChatViewStyle {
    public struct Message: Hashable {
        public let font: UIFont
        public let infoFont: UIFont
        public let textColor: UIColor
        public let infoColor: UIColor
        public let backgroundColor: UIColor
        public let borderColor: UIColor
        public let borderWidth: CGFloat
        public let cornerRadius: CGFloat
        
        init(font: UIFont = .chatRegular,
             infoFont: UIFont = .chatSmall,
             textColor: UIColor = .black,
             infoColor: UIColor = .chatGray,
             backgroundColor: UIColor = .white,
             borderColor: UIColor = .messageBorder,
             borderWidth: CGFloat = 1,
             cornerRadius: CGFloat = .messageCornerRadius) {
            self.font = font
            self.infoFont = infoFont
            self.textColor = textColor
            self.infoColor = infoColor
            self.backgroundColor = backgroundColor
            self.borderColor = borderColor
            self.borderWidth = borderWidth
            self.cornerRadius = cornerRadius
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(font)
            hasher.combine(infoFont)
            hasher.combine(textColor)
            hasher.combine(infoColor)
            hasher.combine(backgroundColor)
            hasher.combine(borderColor)
            hasher.combine(borderWidth)
            hasher.combine(cornerRadius)
        }
    }
}
