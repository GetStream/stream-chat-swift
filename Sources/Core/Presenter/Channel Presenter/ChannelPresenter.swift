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
    
    /// A callback for the adding an extra data for a new message.
    public var messageExtraDataCallback: MessageExtraDataCallback?
    
    private let channelType: ChannelType
    private let channelId: String
    let channelAtomic = Atomic<Channel>()
    
    /// A channel (see `Channel`).
    public var channel: Channel {
        return channelAtomic.get(defaultValue: Channel(type: channelType, id: channelId))
    }
    
    /// A parent message for replies.
    public let parentMessage: Message?
    /// Query options.
    public let queryOptions: QueryOptions
    /// An edited message.
    public var editMessage: Message?
    /// Show statuses separators, e.g. Today
    public private(set) var showStatuses = true
    
    private var startedTyping = false
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
    private let isReadSubject = PublishSubject<Void>()
    
    /// Check if the channel has unread messages.
    public var isUnread: Bool {
        return channel.config.readEventsEnabled && unreadMessageReadAtomic.get() != nil
    }
    
    /// Check if the channel has ephemeral message, e.g. Giphy preview.
    public var hasEphemeralMessage: Bool { return ephemeralMessage != nil }
    /// An ephemeral message, e.g. Giphy preview.
    public var ephemeralMessage: Message? { return (try? ephemeralSubject.value())?.message }
    
    /// Check if the user can reply (create a thread) to a message.
    public var canReply: Bool {
        return parentMessage == nil && channel.config.repliesEnabled
    }
    
    /// An observable view changes (see `ViewChanges`).
    public private(set) lazy var changes =
        Driver.merge(parentMessage == nil ? parsedChannelResponse(messagesRequest) : repliesRequest,
                     parentMessage == nil ? parsedChannelResponse(messagesDatabaseFetch) : .empty(),
                     webSocketChanges,
                     ephemeralChanges,
                     connectionErrors)
    
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
        .flatMapLatest { [weak self] pagination -> Observable<ChannelResponse> in
            self?.channel.fetch(pagination: pagination) ?? .empty()
    }
    
    private lazy var repliesRequest: Driver<ViewChanges> = prepareRequest()
        .filter { [weak self] in $0 != .none && self?.parentMessage != nil }
        .flatMapLatest { [weak self] in (self?.parentMessage?.replies(pagination: $0) ?? .empty()).retry(3) }
        .map { [weak self] in self?.parseReplies($0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    private lazy var webSocketChanges: Driver<ViewChanges> = Client.shared.onEvent(channelType: channelType, channelId: channelId)
        .map { [weak self] in self?.parseChanges(event: $0) ?? .none }
        .filter { $0 != .none }
        .map { [weak self] in self?.mapWithEphemeralMessage($0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    private lazy var ephemeralChanges: Driver<ViewChanges> = ephemeralSubject
        .skip(1)
        .map { [weak self] in self?.parseEphemeralChanges($0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    /// Uploader for images and files.
    public private(set) lazy var uploader = Uploader()
    
    /// An observable updates for the Read event.
    public private(set) lazy var isReadUpdates = isReadSubject.asDriver(onErrorJustReturn: ())
    
    /// Init a presenter with a given channel.
    ///
    /// - Parameters:
    ///     - channel: a channel
    ///     - parentMessage: a parent message for replies
    ///     - showStatuses: shows statuses separators, e.g. Today
    public init(channel: Channel, parentMessage: Message? = nil, queryOptions: QueryOptions = .all, showStatuses: Bool = true) {
        channelType = channel.type
        channelId = channel.id
        channelAtomic.set(channel)
        self.parentMessage = parentMessage
        self.queryOptions = queryOptions
        self.showStatuses = showStatuses
        super.init(pageSize: .messagesPageSize)
    }
    
    /// Init a presenter with a given channel query.
    ///
    /// - Parameters:
    ///     - query: a channel query result with messages
    ///     - showStatuses: shows statuses separators, e.g. Today
    public init(response: ChannelResponse, queryOptions: QueryOptions, showStatuses: Bool = true) {
        channelType = response.channel.type
        channelId = response.channel.id
        channelAtomic.set(response.channel)
        parentMessage = nil
        self.queryOptions = queryOptions
        self.showStatuses = showStatuses
        super.init(pageSize: .messagesPageSize)
        parseResponse(response)
    }
}

// MARK: - Send/Delete Message

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
        var extraData: Codable? = nil
        
        if attachments.isEmpty, let editMessage = editMessage, !editMessage.attachments.isEmpty {
            attachments = editMessage.attachments
        }
        
        if let messageExtraDataCallback = messageExtraDataCallback {
            extraData = messageExtraDataCallback(messageId, text, attachments, parentId)
        }
        
        editMessage = nil
        
        let message = Message(id: messageId,
                              text: text,
                              attachments: attachments,
                              extraData: extraData,
                              parentId: parentId,
                              showReplyInChannel: false)
        
        return channel.send(message: message)
            .do(onNext: { [weak self] in self?.updateEphemeralMessage($0.message) })
            .observeOn(MainScheduler.instance)
    }
}

// MARK: - Send Event

extension ChannelPresenter {
    /// Send a typing event.
    public func sendEvent(isTyping: Bool) -> Observable<Event> {
        guard parentMessage == nil else {
            return .empty()
        }
        
        if isTyping {
            if !startedTyping {
                startedTyping = true
                return channel.send(eventType: .typingStart).observeOn(MainScheduler.instance)
            }
        } else if startedTyping {
            startedTyping = false
            return channel.send(eventType: .typingStop).observeOn(MainScheduler.instance)
        }
        
        return .empty()
    }
    
    /// Send Read event if the app is active.
    ///
    /// - Returns: an observable completion.
    public func markReadIfPossible() -> Observable<Void> {
        guard InternetConnection.shared.isAvailable else {
            return .empty()
        }
        
        guard let oldUnreadMessageRead = unreadMessageReadAtomic.get() else {
            Client.shared.logger?.log("🎫", "Skip read.")
            return .empty()
        }
        
        unreadMessageReadAtomic.set(nil)
        
        return Observable.just(())
            .subscribeOn(MainScheduler.instance)
            .filter { UIApplication.shared.appState == .active }
            .do(onNext: { Client.shared.logger?.log("🎫", "Send Message Read. Unread from \(oldUnreadMessageRead.lastReadDate)") })
            .flatMap { [weak self] in self?.channel.markRead() ?? .empty() }
            .do(onNext: { [weak self] _ in
                self?.unreadMessageReadAtomic.set(nil)
                self?.isReadSubject.onNext(())
                Client.shared.logger?.log("🎫", "Message Read done.")
                }, onError: { [weak self] error in
                    self?.unreadMessageReadAtomic.set(oldUnreadMessageRead)
                    self?.isReadSubject.onError(error)
                    ClientLogger.log("🎫", error, message: "Send Message Read error.")
            })
            .map { _ in Void() }
    }
}
