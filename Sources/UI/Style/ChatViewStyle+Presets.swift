//
//  ChatViewStyle+Presets.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 16/04/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: Presets

extension ChatViewStyle {
    
    // MARK: Dark
    
    /// A dark chat view style.
    public static let dark =
        ChatViewStyle(
            channel: ChannelViewStyle(backgroundColor: .chatSuperDarkGray,
                                      nameColor: .chatGray,
                                      nameUnreadColor: .white,
                                      messageUnreadColor: .white),
            
            composer: ComposerViewStyle(textColor: .white,
                                        helperContainerBackgroundColor: .chatDarkGray,
                                        replyInChannelViewStyle: .init(color: .chatGray, selectedColor: .white),
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
    
    // MARK: - Dynamic
    
    /// A dynamic chat view style for iOS 13+.
    @available(iOS 13, *)
    public static let dynamic =
        ChatViewStyle(
            channel: ChannelViewStyle(backgroundColor: .systemBackground,
                                      separatorStyle: .init(color: .separator),
                                      nameColor: .secondaryLabel,
                                      nameUnreadColor: .label,
                                      messageColor: .secondaryLabel,
                                      messageUnreadColor: .label,
                                      messageDeletedColor: .secondaryLabel,
                                      dateColor: .tertiaryLabel),
            
            composer: ComposerViewStyle(textColor: .label,
                                        placeholderTextColor: .secondaryLabel,
                                        helperContainerBackgroundColor: .tertiarySystemBackground,
                                        replyInChannelViewStyle: .init(color: .secondaryLabel, selectedColor: .label),
                                        states: [.active: .init(tintColor: .dynamicAccent, borderWidth: 2),
                                                 .edit: .init(tintColor: .dynamicAccent2, borderWidth: 2),
                                                 .disabled: .init(tintColor: .systemGray, borderWidth: 2)]),
            
            incomingMessage: MessageViewStyle(chatBackgroundColor: .systemBackground,
                                              textColor: .label,
                                              backgroundColor: .systemBackground,
                                              borderColor: .systemGray5,
                                              reactionViewStyle: .init(backgroundColor: .chatDarkGray,
                                                                       chatBackgroundColor: .systemBackground)),
            
            outgoingMessage: MessageViewStyle(alignment: .right,
                                              chatBackgroundColor: .systemBackground,
                                              textColor: .label,
                                              backgroundColor: .systemGray6,
                                              borderWidth: 0,
                                              reactionViewStyle: .init(alignment: .right,
                                                                       backgroundColor: .chatDarkGray,
                                                                       chatBackgroundColor: .systemBackground)))
}
