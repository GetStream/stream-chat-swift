//
//  ChatItem.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 13/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public enum ChatItem: Equatable {
    case loading(_ inProgress: Bool)
    case status(_ title: String, _ subtitle: String?, _ highlighted: Bool)
    case channelPresenter(ChannelPresenter)
    case message(Message, _ usersRead: [User])
    case error(Error)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        
        return false
    }
    
    var channelPresenter: ChannelPresenter? {
        if case .channelPresenter(let channelPresenter) = self {
            return channelPresenter
        }
        
        return nil
    }
    
    var message: Message? {
        if case .message(let message, _) = self {
            return message
        }
        
        return nil
    }
    
    var messageReadUsers: [User] {
        if case .message(_, let users) = self {
            return users
        }
        
        return []
    }
    
    public static func == (lhs: ChatItem, rhs: ChatItem) -> Bool {
        switch (lhs, rhs) {
        case let (.loading(inProgress1), .loading(inProgress2)):
            return inProgress1 == inProgress2
        case let (.channelPresenter(channelPresenter1), .channelPresenter(channelPresenter2)):
            return channelPresenter1.channel == channelPresenter2.channel
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

// MARK: - Array extension for ChatItem

extension Array where Element == ChatItem {
    
    func firstIndex(whereChannelId channelId: String) -> Int? {
        return lastIndex(where: { item -> Bool in
            if case .channelPresenter(let channelPresenter) = item {
                return channelPresenter.channel.id == channelId
            }
            
            return false
        })
    }
    
    func lastIndex(whereMessageId messageId: String) -> Int? {
        return lastIndex(where: { item -> Bool in
            if case .message(let message, _) = item {
                return message.id == messageId
            }
            
            return false
        })
    }
    
    func findLastMessage(before beforeIndex: Int = .max) -> (index: Int, message: Message)? {
        guard !isEmpty else {
            return nil
        }
        
        for (index, item) in enumerated().reversed() where index < beforeIndex  {
            if case .message(let message, _) = item {
                return (index, message)
            }
        }
        
        return nil
    }

    func firstIndexWhereStatusLoading() -> Int? {
        return firstIndex(where: { item -> Bool in
            if case .loading = item {
                return true
            }
            
            return false
        })
    }
    
    func firstIndex(whereStatusTitle title: String) -> Int? {
        return firstIndex(where: { item -> Bool in
            if case .status(let itemTitle, _, _) = item {
                return itemTitle == title
            }
            
            return false
        })
    }
    
    func lastIndex(whereStatusTitle title: String) -> Int? {
        return lastIndex(where: { item -> Bool in
            if case .status(let itemTitle, _, _) = item {
                return itemTitle == title
            }
            
            return false
        })
    }
}
