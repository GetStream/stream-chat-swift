//
//  ChannelPresenter.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import RxSwift
import RxCocoa

/// A channel presenter.
public final class ChannelPresenter: Presenter {
    typealias EphemeralType = (message: Message?, updated: Bool)
    
    /// A callback type for the adding an extra data for a new message.
    public typealias MessageExtraDataCallback =
        (_ id: String, _ text: String, _ attachments: [Attachment], _ parentId: String?) -> Codable?
    
    /// A callback for the adding an extra data for a new message.
    public var messageExtraDataCallback: MessageExtraDataCallback?
    
    let channelType: ChannelType
    let channelId: String
    let channelPublishSubject = PublishSubject<Channel>()
    
    private(set) lazy var channelAtomic = Atomic<Channel> { [weak self] channel, oldChannel in
        if let channel = channel {
            if let oldChannel = oldChannel {
                channel.banEnabling = oldChannel.banEnabling
            }
            
            self?.channelPublishSubject.onNext(channel)
        }
    }
    
    /// A channel (see `Channel`).
    public var channel: Channel { channelAtomic.get(default: .unused) }
    /// A parent message for replies.
    public let parentMessage: Message?
    /// Query options.
    public let queryOptions: QueryOptions
    /// An edited message.
    public var editMessage: Message?
    /// Show statuses separators, e.g. Today
    public private(set) var showStatuses = true
    let lastMessageAtomic = Atomic<Message>()
    /// The last parsed message from WebSocket events.
    public var lastMessage: Message? { lastMessageAtomic.get() }
    var lastAddedOwnMessage: Message?
    var lastParsedEvent: StreamChatClient.Event?
    var lastWebSocketEventViewChanges: ViewChanges?
    
    /// A list of typing users (see `TypingUser`).
    public internal(set) var typingUsers: [TypingUser] = []
    var startedTyping = false
    
    var messageReadsToMessageId: [MessageRead: String] = [:]
    /// Check if the channel has unread messages.
    public var isUnread: Bool { channel.config.readEventsEnabled && channel.unreadMessageRead != nil }
    
    let ephemeralSubject = BehaviorSubject<EphemeralType>(value: (nil, false))
    /// Check if the channel has ephemeral message, e.g. Giphy preview.
    public var hasEphemeralMessage: Bool { ephemeralMessage != nil }
    /// An ephemeral message, e.g. Giphy preview.
    public var ephemeralMessage: Message? { (try? ephemeralSubject.value())?.message }
    
    /// Check if the user can reply (create a thread) to a message.
    public var canReply: Bool { parentMessage == nil && channel.config.repliesEnabled }
    
    /// A filter to discard channel events.
    public var eventsFilter: StreamChatClient.Event.Filter?
    
    /// An observable view changes (see `ViewChanges`).
    lazy var rxChanges = rx.setupChanges()
    lazy var rxParsedMessagesRequest = rx.parsedChannelResponse(rx.messagesRequest)
    
    /// Uploader for images and files.
    public private(set) lazy var uploader = Uploader()
    
    /// Init a presenter with a given channel.
    ///
    /// - Parameters:
    ///     - channel: a channel
    ///     - parentMessage: a parent message for replies
    ///     - showStatuses: shows statuses separators, e.g. Today
    public init(channel: Channel, parentMessage: Message? = nil, queryOptions: QueryOptions = .all, showStatuses: Bool = true) {
        channelType = channel.type
        channelId = channel.id
        self.parentMessage = parentMessage
        self.queryOptions = queryOptions
        self.showStatuses = showStatuses
        super.init(pageSize: .messagesPageSize)
        channelAtomic.set(channel)
    }
    
    /// Init a presenter with a given channel query.
    ///
    /// - Parameters:
    ///     - query: a channel query result with messages
    ///     - showStatuses: shows statuses separators, e.g. Today
    public init(response: ChannelResponse, queryOptions: QueryOptions, showStatuses: Bool = true) {
        channelType = response.channel.type
        channelId = response.channel.id
        parentMessage = nil
        self.queryOptions = queryOptions
        self.showStatuses = showStatuses
        super.init(pageSize: .messagesPageSize)
        parse(response: response)
    }
}

// MARK: - Changes

public extension ChannelPresenter {
    
    /// Subscribes for `ViewChanges`.
    /// - Parameter onNext: a co    mpletion block with `ViewChanges`.
    /// - Returns: a subscription.
    func changes(_ onNext: @escaping Client.Completion<ViewChanges>) -> Subscription {
        rx.changes.asObservable().bind(to: onNext)
    }
    
    /// An observable channel (see `Channel`).
    func channelDidUpdate(_ onNext: @escaping Client.Completion<Channel>) -> Subscription {
        rx.channelDidUpdate.asObservable().bind(to: onNext)
    }
}

// MARK: - Send Message

extension ChannelPresenter {
    
    /// Create a message by sending a text.
    /// - Parameters:
    ///     - text: a message text
    ///     - completion: a completion block with `MessageResponse`.
    public func send(text: String, _ completion: @escaping Client.Completion<MessageResponse>) {
        rx.send(text: text).bindOnce(to: completion)
    }
    
    func createMessage(with text: String) -> Message {
        let messageId = editMessage?.id ?? ""
        var attachments = uploader.items.compactMap({ $0.attachment })
        let parentId = parentMessage?.id
        var extraData: Codable? = nil
        
        if attachments.isEmpty, let editMessage = editMessage, !editMessage.attachments.isEmpty {
            attachments = editMessage.attachments
        }
        
        if let messageExtraDataCallback = messageExtraDataCallback {
            extraData = messageExtraDataCallback(messageId, text, attachments, parentId)
        }
        
        editMessage = nil
        var mentionedUsers = [User]()
        
        // Add mentiond users
        if !text.isEmpty, text.contains("@"), !channel.members.isEmpty {
            let text = text.lowercased()
            
            channel.members.forEach { member in
                if text.contains("@\(member.user.name.lowercased())") {
                    mentionedUsers.append(member.user)
                }
            }
        }
        
        return Message(id: messageId,
                       parentId: parentId,
                       text: text,
                       attachments: attachments,
                       mentionedUsers: mentionedUsers,
                       extraData: extraData,
                       showReplyInChannel: false)
    }
}

// MARK: - Send Event

extension ChannelPresenter {
    
    /// Send a typing event.
    /// - Parameters:
    ///   - isTyping: a user typing action.
    ///   - completion: a completion block with `Event`.
    public func sendEvent(isTyping: Bool, _ completion: @escaping Client.Completion<StreamChatClient.Event>) {
        rx.sendEvent(isTyping: isTyping).bindOnce(to: completion)
    }
    
    /// Send Read event if the app is active.
    /// - Returns: an observable completion.
    public func markReadIfPossible(_ completion: @escaping Client.Completion<StreamChatClient.Event> = { _ in }) {
        rx.markReadIfPossible().bindOnce(to: completion)
    }
}
