//
//  ChatViewStyle+Extensions.swift
//  ChatExample
//
//  Created by Alexey Bukhtin on 06/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

extension ChatViewStyle {
    static let whatsapp: ChatViewStyle = {
        let separatorStyle = SeparatorStyle(inset: .init(top: 0, left: 86, bottom: 0, right: 0))
        let channelAvatar = AvatarViewStyle(radius: 30, placeholderFont: .systemFont(ofSize: 24, weight: .bold))
        
        let channel = ChannelViewStyle(backgroundColor: .white,
                                       separatorStyle: separatorStyle,
                                       avatarViewStyle: channelAvatar,
                                       nameNumberOfLines: 1,
                                       nameFont: .systemFont(ofSize: 17, weight: .bold),
                                       nameColor: .black,
                                       nameUnreadFont: .systemFont(ofSize: 17, weight: .bold),
                                       nameUnreadColor: .black,
                                       messageNumberOfLines: 2,
                                       messageFont: .systemFont(ofSize: 15),
                                       messageColor: .gray,
                                       messageUnreadFont: .systemFont(ofSize: 15),
                                       messageUnreadColor: .gray,
                                       messageDeletedFont: .systemFont(ofSize: 15),
                                       messageDeletedColor: .gray,
                                       verticalTextAlignment: .top,
                                       dateFont: .systemFont(ofSize: 14),
                                       dateColor: .gray,
                                       height: 82,
                                       spacing: Spacing(horizontal: 15, vertical: 4),
                                       edgeInsets: .init(top: 10, left: 16, bottom: 10, right: 14))
        
        let imageData = try! Data(contentsOf: URL(string: "https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png")!)
        let backgroundImage = UIImage(data: imageData, scale: 2)!
        let backgroundColor = UIColor(patternImage: backgroundImage)
        let textFont = UIFont.systemFont(ofSize: 16)
        
        let reactionViewStyle = ReactionViewStyle(alignment: .left,
                                                  textColor: .black,
                                                  backgroundColor: .white,
                                                  chatBackgroundColor: backgroundColor,
                                                  tailMessageCornerRadius: 8)
        
        let incomingMessage = MessageViewStyle(alignment: .left,
                                               avatarViewStyle: nil,
                                               chatBackgroundColor: backgroundColor,
                                               font: textFont,
                                               nameFont: .systemFont(ofSize: 12, weight: .bold),
                                               infoFont: .systemFont(ofSize: 12),
                                               textColor: .black,
                                               infoColor: .gray,
                                               backgroundColor: .white,
                                               borderWidth: 0,
                                               cornerRadius: 8,
                                               spacing: .init(horizontal: 0, vertical: 2),
                                               edgeInsets: .init(top: 5, left: 10, bottom: 5, right: 10),
                                               reactionViewStyle: reactionViewStyle)
        
        var outgoingMessage = incomingMessage
        outgoingMessage.alignment = .right
        outgoingMessage.backgroundColor = UIColor(red: 0.88, green: 0.96, blue: 0.79, alpha: 1.00)
        
        outgoingMessage.reactionViewStyle = ReactionViewStyle(alignment: .right,
                                                              textColor: .black,
                                                              backgroundColor: outgoingMessage.backgroundColor,
                                                              chatBackgroundColor: backgroundColor,
                                                              tailMessageCornerRadius: 8)
        
        let composer = ComposerViewStyle(backgroundColor: UIColor(red: 0.97, green: 0.96, blue: 0.96, alpha: 0.5),
                                         cornerRadius: 0,
                                         height: 44,
                                         edgeInsets: .zero,
                                         states: [.normal: .init(tintColor: .chatGray, borderWidth: 1),
                                                  .active: .init(tintColor: .chatGray, borderWidth: 1),
                                                  .edit: .init(tintColor: .chatGreen, borderWidth: 1),
                                                  .disabled: .init(tintColor: .chatGray, borderWidth: 1)])
        
        return ChatViewStyle(channel: channel,
                             composer: composer,
                             incomingMessage: incomingMessage,
                             outgoingMessage: outgoingMessage)
    }()
}
