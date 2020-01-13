//
//  ChannelPresenter+RxRequests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public extension Reactive where Base == ChannelPresenter {
    
    /// An observable `ViewChanges`.
    var changes: Driver<ViewChanges> {
        return base.rxChanges
    }
    
    /// An observable `Channel`.
    var channelDidUpdate: Driver<Channel> {
        return base.channelPublishSubject.asDriver(onErrorJustReturn: Channel(type: base.channelType, id: base.channelId))
    }
    
    /// Create a message by sending a text.
    /// - Parameter text: a message text.
    /// - Returns: an observable `MessageResponse`.
    func send(text: String) -> Observable<MessageResponse> {
        return base.channel.rx.send(message: base.createMessage(with: text))
            .do(onNext: { [weak base] in base?.updateEphemeralMessage($0.message) })
            .observeOn(MainScheduler.instance)
    }
    
    /// Send a typing event.
    /// - Parameter isTyping: a user typing action.
    func sendEvent(isTyping: Bool) -> Observable<Event> {
        guard base.parentMessage == nil else {
            return .empty()
        }
        
        if isTyping {
            if !base.startedTyping {
                base.startedTyping = true
                return base.channel.rx.send(eventType: .typingStart).observeOn(MainScheduler.instance)
            }
        } else if base.startedTyping {
            base.startedTyping = false
            return base.channel.rx.send(eventType: .typingStop).observeOn(MainScheduler.instance)
        }
        
        return .empty()
    }
    
    /// Send Read event if the app is active.
    /// - Returns: an observable completion.
    func markReadIfPossible() -> Observable<Void> {
        guard InternetConnection.shared.isAvailable, base.channel.config.readEventsEnabled else {
            return .empty()
        }
        
        guard let unreadMessageRead = base.unreadMessageReadAtomic.get() else {
            Client.shared.logger?.log("🎫 Skip read. No unreadMessageRead.")
            return .empty()
        }
        
        base.unreadMessageReadAtomic.set(nil)
        
        return Observable.just(())
            .subscribeOn(MainScheduler.instance)
            .filter { UIApplication.shared.appState == .active }
            .do(onNext: { Client.shared.logger?.log("🎫 Send Message Read. Unread from \(unreadMessageRead.lastReadDate)") })
            .flatMapLatest { [weak base] in base?.channel.rx.markRead() ?? .empty() }
            .do(
                onNext: { [weak base] _ in
                    base?.unreadMessageReadAtomic.set(nil)
                    base?.channel.unreadCountAtomic.set(0)
                    Client.shared.logger?.log("🎫 Message Read done.")
                },
                onError: { [weak base] error in
                    base?.unreadMessageReadAtomic.set(unreadMessageRead)
                    Client.shared.logger?.log(error, message: "🎫 Send Message Read error.")
            })
            .void()
    }
    
    /// Dispatch an ephemeral message action, e.g. shuffle, send.
    /// - Parameters:
    ///   - action: an attachment action for the ephemeral message.
    ///   - message: an ephemeral message
    func dispatchEphemeralMessageAction(_ action: Attachment.Action, message: Message) -> Observable<MessageResponse> {
        if action.isCancelled || action.isSend {
            base.ephemeralSubject.onNext((nil, true))
            
            if action.isCancelled {
                return .empty()
            }
        }
        
        return base.channel.rx.send(action: action, for: message)
            .do(onNext: { [weak base] in base?.updateEphemeralMessage($0.message) })
            .observeOn(MainScheduler.instance)
    }
}

extension Reactive where Base == ChannelPresenter {
    
    func setupChanges() -> Driver<ViewChanges> {
        return  (base.channel.id.isEmpty
            // Get a channel with a generated channel id.
            ? base.channel.rx.query()
                .map({ [weak base] channelResponse -> Void in
                    // Update the current channel.
                    base?.channelAtomic.set(channelResponse.channel)
                    return Void()
                })
                .asDriver(onErrorJustReturn: ())
            : Driver.just(()))
            // Merge all view changes from all sources.
            .flatMapLatest({ [weak base] _ -> Driver<ViewChanges> in
                guard let base = base else {
                    return .empty()
                }
                
                return Driver.merge(
                    // Messages from requests.
                    base.parentMessage == nil
                        ? base.rxParsedMessagesRequest
                        : self.parsedRepliesResponse(self.repliesRequest),
                    // Messages from database.
                    base.parentMessage == nil
                        ? self.parsedChannelResponse(self.messagesDatabaseFetch)
                        : self.parsedRepliesResponse(self.repliesDatabaseFetch),
                    // Events from a websocket.
                    self.webSocketEvents,
                    self.ephemeralMessageEvents,
                    self.connectionErrors
                )
            })
    }
    
    var messagesRequest: Observable<ChannelResponse> {
        return prepareRequest()
            .filter { [weak base] in $0 != .none && base?.parentMessage == nil }
            .flatMapLatest({ [weak base] pagination -> Observable<ChannelResponse> in
                if let base = base {
                    return base.channel.rx.query(pagination: pagination, options: base.queryOptions).retry(3)
                }
                
                return .empty()
            })
    }
    
    func parsedChannelResponse(_ channelResponse: Observable<ChannelResponse>) -> Driver<ViewChanges> {
        return channelResponse
            .map { [weak base] in base?.parseResponse($0) ?? .none }
            .filter { $0 != .none }
            .map { [weak base] in base?.mapWithEphemeralMessage($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    }
}

private extension Reactive where Base == ChannelPresenter {
    
    var messagesDatabaseFetch: Observable<ChannelResponse> {
        return prepareDatabaseFetch()
            .filter { [weak base] in $0 != .none && base?.parentMessage == nil }
            .flatMapLatest({ [weak base] pagination -> Observable<ChannelResponse> in
                base?.channel.fetch(pagination: pagination) ?? .empty()
            })
    }
    
    var repliesRequest: Observable<[Message]> {
        return prepareRequest()
            .filter { [weak base] in $0 != .none && base?.parentMessage != nil }
            .flatMapLatest { [weak base] in (base?.parentMessage?.rx.replies(pagination: $0) ?? .empty()).retry(3) }
    }
    
    var repliesDatabaseFetch: Observable<[Message]> {
        return prepareDatabaseFetch()
            .filter { [weak base] in $0 != .none && base?.parentMessage != nil }
            .flatMapLatest { [weak base] in base?.parentMessage?.fetchReplies(pagination: $0) ?? .empty() }
    }
    
    var webSocketEvents: Driver<ViewChanges> {
        return Client.shared.rx.onEvent(channel: base.channel)
            .filter({ [weak base] event in
                if let eventsFilter = base?.eventsFilter {
                    return eventsFilter(event, base?.channel)
                }
                
                return true
            })
            .map { [weak base] in base?.parseEvents(event: $0) ?? .none }
            .filter { $0 != .none }
            .map { [weak base] in base?.mapWithEphemeralMessage($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    }
    
    var ephemeralMessageEvents: Driver<ViewChanges> {
        return base.ephemeralSubject
            .skip(1)
            .map { [weak base] in base?.parseEphemeralMessageEvents($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    }
    
    func parsedRepliesResponse(_ repliesResponse: Observable<[Message]>) -> Driver<ViewChanges> {
        return repliesResponse
            .map { [weak base] in base?.parseReplies($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    }
}
