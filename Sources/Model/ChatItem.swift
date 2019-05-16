//
//  ChatItem.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 13/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public enum ChatItem: Equatable {
    case loading
    case status(_ title: String, _ subtitle: String?, _ highlighted: Bool)
    case message(Message)
    case error(Error)
    
    public static func == (lhs: ChatItem, rhs: ChatItem) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case let (.message(message1), .message(message2)):
            return message1 == message2
        case let (.status(title1, subtitle1, highlighted1), .status(title2, subtitle2, highlighted2)):
            return title1 == title2 && subtitle1 == subtitle2 && highlighted1 == highlighted2
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}
