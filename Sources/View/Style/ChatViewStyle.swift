//
//  MessageViewStyle.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 05/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public struct ChatViewStyle: Hashable {
    
    public var channel: ChannelViewStyle
    public var composer: ComposerViewStyle
    public var incomingMessage: MessageViewStyle
    public var outgoingMessage: MessageViewStyle
    
    public static let dark =
        ChatViewStyle(channel: ChannelViewStyle(backgroundColor: .chatSuperDarkGray,
                                                titleColor: .white,
                                                messageUnreadColor: .white),
                      composer: ComposerViewStyle(textColor: .white,
                                                  states: [.active: .init(tintColor: .chatBlue, borderWidth: 2),
                                                           .edit: .init(tintColor: .chatGreen, borderWidth: 2),
                                                           .disabled: .init(tintColor: .chatGray, borderWidth: 2)]),
                      incomingMessage: MessageViewStyle(chatBackgroundColor: .chatSuperDarkGray,
                                                        textColor: .white,
                                                        backgroundColor: .chatSuperDarkGray,
                                                        borderColor: .chatGray,
                                                        reactionViewStyle: .init(backgroundColor: .darkGray,
                                                                                 chatBackgroundColor: .chatSuperDarkGray)),
                      outgoingMessage: MessageViewStyle(alignment: .right,
                                                        chatBackgroundColor: .chatSuperDarkGray,
                                                        textColor: .white,
                                                        backgroundColor: .chatDarkGray,
                                                        borderWidth: 0,
                                                        reactionViewStyle: .init(alignment: .right,
                                                                                 backgroundColor: .darkGray,
                                                                                 chatBackgroundColor: .chatSuperDarkGray)))
    
    public init(channel: ChannelViewStyle = .init(),
                composer: ComposerViewStyle = .init(),
                incomingMessage: MessageViewStyle = .init(),
                outgoingMessage: MessageViewStyle = .init(alignment: .right,
                                                          backgroundColor: .chatSuperLightGray,
                                                          borderWidth: 0,
                                                          reactionViewStyle: .init(alignment: .right))) {
        self.channel = channel
        self.composer = composer
        self.incomingMessage = incomingMessage
        self.outgoingMessage = outgoingMessage
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(composer)
        hasher.combine(incomingMessage)
        hasher.combine(outgoingMessage)
    }
}
