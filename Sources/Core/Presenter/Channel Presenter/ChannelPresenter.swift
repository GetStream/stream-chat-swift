//
//  ChannelPresenter.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// A channel presenter.
public final class ChannelPresenter: Presenter<ChatItem> {
    typealias EphemeralType = (message: Message?, updated: Bool)
    
    /// A callback type for the adding an extra data for a new message.
    public typealias MessageExtraDataCallback =
        (_ id: String, _ text: String, _ attachments: [Attachment], _ parentId: String?) -> Codable?
    /// A callback type for the adding an extra data for a new reaction.
    public typealias ReactionExtraDataCallback = (_ reactionType: ReactionType, _ score: Int, _ messageId: String) -> Codable?
    
    /// A callback for the adding an extra data for a new message.
    public var messageExtraDataCallback: MessageExtraDataCallback?
    /// A callback for the adding an extra data for a new message.
    public var reactionExtraDataCallback: ReactionExtraDataCallback?
    
    private let channelType: ChannelType
    private let channelId: String
    private let channelPublishSubject = PublishSubject<Channel>()
    
    private(set) lazy var channelAtomic = Atomic<Channel> { [weak self] channel, oldChannel in
        if let channel = channel {
            if let oldChannel = oldChannel {
                channel.banEnabling = oldChannel.banEnabling
            }
            
            self?.channelPublishSubject.onNext(channel)
        }
    }
    
    /// A channel (see `Channel`).
    public var channel: Channel { return channelAtomic.get(defaultValue: .unused) }
    
    /// An observable channel (see `Channel`).
    public internal(set) lazy var channelDidUpdate: Driver<Channel> = channelPublishSubject
        .asDriver(onErrorJustReturn: Channel(type: channelType, id: channelId))
    
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
    public var lastMessage: Message? {
        return lastMessageAtomic.get()
    }
    
    var lastAddedOwnMessage: Message?
    var lastParsedEvent: Event?
    var lastWebSocketEventViewChanges: ViewChanges?
    
    lazy var unreadMessageReadAtomic = Atomic<MessageRead>()
    
    /// A list of typing users (see `TypingUser`).
    public internal(set) var typingUsers: [TypingUser] = []
    var messageReadsToMessageId: [MessageRead: String] = [:]
    let ephemeralSubject = BehaviorSubject<EphemeralType>(value: (nil, false))
    
    /// Check if the channel has unread messages.
    public var isUnread: Bool {
        return channel.config.readEventsEnabled && unreadMessageReadAtomic.get() != nil
    }
    
    /// The current user message read state.
    public var messageRead: MessageRead? {
        return unreadMessageReadAtomic.get()
    }
    
    /// Check if the channel has ephemeral message, e.g. Giphy preview.
    public var hasEphemeralMessage: Bool { return ephemeralMessage != nil }
    /// An ephemeral message, e.g. Giphy preview.
    public var ephemeralMessage: Message? { return (try? ephemeralSubject.value())?.message }
    
    /// Check if the user can reply (create a thread) to a message.
    public var canReply: Bool {
        return parentMessage == nil && channel.config.repliesEnabled
    }
    
    /// A filter to discard channel events.
    public var eventsFilter: Event.Filter?
    
    /// An observable view changes (see `ViewChanges`).
    public private(set) lazy var changes =
        (channel.id.isEmpty
            // Get a channel with a generated channel id.
            ? channel.query()
                .map({ [weak self] channelResponse -> Void in
                    // Update the current channel.
                    self?.channelAtomic.set(channelResponse.channel)
                    return Void()
                })
                .asDriver(onErrorJustReturn: ())
            : Driver.just(()))
            // Merge all view changes from all sources.
            .flatMapLatest({ [weak self] _ -> Driver<ViewChanges> in
                guard let self = self else {
                    return .empty()
                }
                
                return Driver.merge(
                    // Messages from requests.
                    self.parentMessage == nil ? self.parsedMessagesRequest : self.parsedRepliesResponse(self.repliesRequest),
                    // Messages from database.
                    self.parentMessage == nil
                        ? self.parsedChannelResponse(self.messagesDatabaseFetch)
                        : self.parsedRepliesResponse(self.repliesDatabaseFetch),
                    // Events from a websocket.
                    self.webSocketEvents,
                    self.ephemeralMessageEvents,
                    self.connectionErrors
                )
            })
    
    lazy var parsedMessagesRequest = parsedChannelResponse(messagesRequest)
    
    private lazy var messagesRequest: Observable<ChannelResponse> = prepareRequest()
        .filter { [weak self] in $0 != .none && self?.parentMessage == nil }
        .flatMapLatest { [weak self] pagination -> Observable<ChannelResponse> in
            if let self = self {
                return self.channel.query(pagination: pagination, options: self.queryOptions).retry(3)
            }
            
            return .empty()
    }
    
    private lazy var messagesDatabaseFetch: Observable<ChannelResponse> = prepareDatabaseFetch()
        .filter { [weak self] in $0 != .none && self?.parentMessage == nil }
        .flatMapLatest({ [weak self] pagination -> Observable<ChannelResponse> in
            self?.channel.fetch(pagination: pagination) ?? .empty()
        })
    
    private lazy var repliesRequest: Observable<[Message]> = prepareRequest()
        .filter { [weak self] in $0 != .none && self?.parentMessage != nil }
        .flatMapLatest { [weak self] in (self?.parentMessage?.replies(pagination: $0) ?? .empty()).retry(3) }
    
    private lazy var repliesDatabaseFetch: Observable<[Message]> = prepareDatabaseFetch()
        .filter { [weak self] in $0 != .none && self?.parentMessage != nil }
        .flatMapLatest { [weak self] in self?.parentMessage?.fetchReplies(pagination: $0) ?? .empty() }
    
    private lazy var webSocketEvents: Driver<ViewChanges> = Client.shared.onEvent(channel: channel)
        .filter({ [weak self] event in
            if let eventsFilter = self?.eventsFilter {
                return eventsFilter(event, self?.channel)
            }
            
            return true
        })
        .map { [weak self] in self?.parseEvents(event: $0) ?? .none }
        .filter { $0 != .none }
        .map { [weak self] in self?.mapWithEphemeralMessage($0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    private lazy var ephemeralMessageEvents: Driver<ViewChanges> = ephemeralSubject
        .skip(1)
        .map { [weak self] in self?.parseEphemeralMessageEvents($0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
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
        parseResponse(response)
    }
}

// MARK: - Send Message

extension ChannelPresenter {
    /// Create a message by sending a text.
    ///
    /// - Parameters:
    ///     - text: a message text
    ///     - completion: a completion blocks
    public func send(text: String) -> Observable<MessageResponse> {
        let messageId = editMessage?.id ?? ""
        var attachments = uploader.items.compactMap({ $0.attachment })
        let parentId = parentMessage?.id
        var extraData: Codable?
        
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
        
        let message = Message(id: messageId,
                              parentId: parentId,
                              text: text,
                              attachments: attachments,
                              mentionedUsers: mentionedUsers,
                              extraData: extraData,
                              showReplyInChannel: false)
        
        return channel.send(message: message)
            .do(onNext: { [weak self] in self?.updateEphemeralMessage($0.message) })
            .observeOn(MainScheduler.instance)
    }
}

// MARK: - Send Event

extension ChannelPresenter {
    /// Send Read event if the app is active.
    /// - Returns: an observable completion.
    public func markReadIfPossible() -> Observable<Void> {
        guard InternetConnection.shared.isAvailable, channel.config.readEventsEnabled else {
            return .empty()
        }
        
        guard let unreadMessageRead = unreadMessageReadAtomic.get() else {
            Client.shared.logger?.log("🎫 Skip read. No unreadMessageRead.")
            return .empty()
        }
        
        unreadMessageReadAtomic.set(nil)
        
        return Observable.just(())
            .subscribeOn(MainScheduler.instance)
            .filter { UIApplication.shared.appState == .active }
            .do(onNext: {
                Client.shared.logger?.log("🎫 Send Message Read. Unread from \(unreadMessageRead.lastReadDate)")
            })
            .flatMapLatest { [weak self] in self?.channel.markRead() ?? .empty() }
            .do(
                onNext: { [weak self] _ in
                    self?.unreadMessageReadAtomic.set(nil)
                    self?.channel.unreadCountAtomic.set(0)
                    Client.shared.logger?.log("🎫 Message Read done.")
                },
                onError: { [weak self] error in
                    self?.unreadMessageReadAtomic.set(unreadMessageRead)
                    Client.shared.logger?.log(error, message: "🎫 Send Message Read error.")
            })
            .void()
    }
}
