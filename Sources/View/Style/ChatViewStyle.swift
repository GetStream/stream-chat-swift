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
    public var outgoingMessage = MessageViewStyle(alignment: .right, backgroundColor: .chatSuperLightGray, borderWidth: 0)
    
    public static let dark =
        ChatViewStyle(backgroundColor: .chatSuperDarkGray,
                      incomingMessage: MessageViewStyle(chatBackgroundColor: .chatSuperDarkGray,
                                                        textColor: .white,
                                                        backgroundColor: .chatSuperDarkGray,
                                                        borderColor: .chatGray,
                                                        reactionViewStyle: ReactionViewStyle(backgroundColor: .darkGray)),
                      outgoingMessage: MessageViewStyle(alignment: .right,
                                                        chatBackgroundColor: .chatSuperDarkGray,
                                                        textColor: .white,
                                                        backgroundColor: .chatDarkGray,
                                                        borderWidth: 0,
                                                        reactionViewStyle: ReactionViewStyle(alignment: .right,
                                                                                             backgroundColor: .darkGray)))
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(backgroundColor)
        hasher.combine(incomingMessage)
        hasher.combine(outgoingMessage)
    }
}
