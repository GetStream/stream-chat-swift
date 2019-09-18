//
//  ChatItem.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A chat item type for view elements.
public enum ChatItem: Equatable {
    /// A title for the yesterday separator.
    public static var statusYesterdayTitle = "Yesterday"
    /// A title for the today separator.
    public static var statusTodayTitle = "Today"
    
    /// A loading item.
    case loading(_ inProgress: Bool)
    /// A status item.
    case status(_ title: String, _ subtitle: String?, _ highlighted: Bool)
    /// A channel presenter item.
    case channelPresenter(ChannelPresenter)
    /// A message.
    case message(Message, _ usersRead: [User])
    /// An error.
    case error(Error)
    
    /// Check if the chat item is loading.
    public var isLoading: Bool {
        if case .loading = self {
            return true
        }
        
        return false
    }
    
    /// Return a channel presenter if the chat item is a channel presenter.
    public var channelPresenter: ChannelPresenter? {
        if case .channelPresenter(let channelPresenter) = self {
            return channelPresenter
        }
        
        return nil
    }
    
    /// Return a message if the chat item is a message.
    public var message: Message? {
        if case .message(let message, _) = self {
            return message
        }
        
        return nil
    }
    
    /// Return read users for a message chat item.
    public var messageReadUsers: [User] {
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

public extension Array where Element == ChatItem {
    
    /// Find the first index of an `ChatItem` of a channel presenter with a given channel id.
    ///
    /// - Parameter channelId: a channelId of a searching `ChatItem` of a channel presenter.
    /// - Returns: an index of an `ChatItem` with a channel presenter.
    func firstIndex(whereChannelId channelId: String) -> Int? {
        return lastIndex(where: { item -> Bool in
            if case .channelPresenter(let channelPresenter) = item {
                return channelPresenter.channel.id == channelId
            }
            
            return false
        })
    }
    
    /// Find the last index of an `ChatItem` of a message with a given message id.
    ///
    /// - Parameter messageId: a messageId of a searching `ChatItem` of a message.
    /// - Returns: an index of an `ChatItem` with a message.
    func lastIndex(whereMessageId messageId: String) -> Int? {
        return lastIndex(where: { item -> Bool in
            if case .message(let message, _) = item, !message.id.isEmpty {
                return message.id == messageId
            }
            
            return false
        })
    }
    
    /// Find the last `ChatItem` of a message before a given index.
    ///
    /// - Parameter beforeIndex: an index of `ChatItem` where to start a search of `ChatItem` message.
    /// - Returns: a tuple of `ChatItem` index and a message.
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
    
    /// Find the first index of an `ChatItem` of a status loading.
    ///
    /// - Returns: an index of a `ChatItem` status loading.
    func firstIndexWhereStatusLoading() -> Int? {
        return firstIndex(where: { item -> Bool in
            if case .loading = item {
                return true
            }
            
            return false
        })
    }
    
    /// Find the first index of an `ChatItem` of a status with a given title.
    ///
    /// - Parameter title: a searching status title.
    /// - Returns: an index of a `ChatItem` status.
    func firstIndex(whereStatusTitle title: String) -> Int? {
        return firstIndex(where: { item -> Bool in
            if case .status(let itemTitle, _, _) = item {
                return itemTitle == title
            }
            
            return false
        })
    }
    
    /// Find the last index of an `ChatItem` of a status with a given title.
    ///
    /// - Parameter title: a searching status title.
    /// - Returns: an index of a `ChatItem` status.
    func lastIndex(whereStatusTitle title: String) -> Int? {
        return lastIndex(where: { item -> Bool in
            if case .status(let itemTitle, _, _) = item {
                return itemTitle == title
            }
            
            return false
        })
    }
}
