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
    public var incomingMessage = MessageViewStyle()
    public var outgoingMessage = MessageViewStyle(alignment: .right, backgroundColor: .messageBorder, borderWidth: 0)
    
    public static let dark =
        ChatViewStyle(backgroundColor: .init(white: 0.1, alpha: 1),
                      incomingMessage: MessageViewStyle(chatBackgroundColor: .init(white: 0.1, alpha: 1),
                                                        textColor: .white,
                                                        backgroundColor: .init(white: 0.1, alpha: 1),
                                                        borderColor: .chatGray),
                      outgoingMessage: MessageViewStyle(alignment: .right,
                                                        chatBackgroundColor: .init(white: 0.1, alpha: 1),
                                                        textColor: .white,
                                                        backgroundColor: .init(white: 0.2, alpha: 1),
                                                        borderWidth: 0))
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(backgroundColor)
        hasher.combine(incomingMessage)
        hasher.combine(outgoingMessage)
    }
}
