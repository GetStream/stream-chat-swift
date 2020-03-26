//
//  ChannelPresenter+RxRequests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import RxSwift
import RxCocoa

extension ChannelPresenter {
    fileprivate static var rxChangesKey: UInt8 = 0
    fileprivate static var rxParsedMessagesRequestKey: UInt8 = 0
}

extension Reactive where Base == ChannelPresenter {
    
    /// An observable `ViewChanges`.
    public var changes: Driver<ViewChanges> {
        associated(to: base, key: &ChannelPresenter.rxChangesKey) { [weak base] in
            guard let base = base else {
                return .empty()
            }
            
            return (base.channel.id.isEmpty
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
                            ? base.rx.parsedMessagesRequest
                            : base.rx.parsedRepliesResponse(base.rx.repliesRequest),
                        // Events from a websocket.
                        base.rx.webSocketEvents,
                        base.rx.ephemeralMessageEvents,
                        base.rx.connectionErrors
                    )
                })
        }
    }
    
    var messagesRequest: Observable<ChannelResponse> {
        prepareRequest()
            .filter { [weak base] in $0 != .none && base?.parentMessage == nil }
            .flatMapLatest({ [weak base] pagination -> Observable<ChannelResponse> in
                guard let base = base else {
                    return .empty()
                }
                
                // Request for the fist page.
                if pagination.isLimit {
                    return base.channel.rx.query(messagesPagination: pagination, options: base.queryOptions).retry(3)
                }
                
                // We need only the next page of messages.
                // Skip members and default query options.
                return base.channel.rx
                    .query(messagesPagination: pagination, membersPagination: .limit(0), options: .state)
                    .retry(3)
            })
    }
    
    var parsedMessagesRequest: Driver<ViewChanges> {
        associated(to: base, key: &ChannelPresenter.rxParsedMessagesRequestKey) { [weak base] in
            guard let base = base else {
                return .empty()
            }
            
            return base.rx.parsedChannelResponse(base.rx.messagesRequest)
        }
    }
    
    func parsedChannelResponse(_ channelResponse: Observable<ChannelResponse>) -> Driver<ViewChanges> {
        channelResponse
            .map { [weak base] in base?.parse(response: $0) ?? .none }
            .filter { $0 != .none }
            .map { [weak base] in base?.mapWithEphemeralMessage($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError($0))) }
    }
}

public extension Reactive where Base == ChannelPresenter {
    
    /// An observable `Channel`.
    var channelDidUpdate: Driver<Channel> {
        base.channelPublishSubject.asDriver(onErrorJustReturn: Channel.unused)
    }
    
    /// Create a message by sending a text.
    /// - Parameter text: a message text.
    /// - Returns: an observable `MessageResponse`.
    func send(text: String) -> Observable<MessageResponse> {
        base.channel.rx.send(message: base.createMessage(with: text))
            .do(onNext: { [weak base] in base?.updateEphemeralMessage($0.message) })
            .observeOn(MainScheduler.instance)
    }
    
    /// Send a typing event.
    /// - Parameter isTyping: a user typing action.
    func sendEvent(isTyping: Bool) -> Observable<StreamChatClient.Event> {
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
    func markReadIfPossible() -> Observable<StreamChatClient.Event> {
        guard InternetConnection.shared.isAvailable, base.channel.readEventsEnabled else {
            return .empty()
        }
        
        guard base.channel.isUnread else {
            Client.shared.logger?.log("🎫↩️ Skip mark read. \(base.channel.unreadCount) at "
                + (base.channel.unreadMessageRead?.lastReadDate.description ?? "<NoLastReadDate>"))
            return .empty()
        }
        
        return Observable.just(())
            .subscribeOn(MainScheduler.instance)
            .filter { UIApplication.shared.applicationState == .active }
            .flatMapLatest { [weak base] in base?.channel.rx.markRead() ?? .empty() }
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

private extension Reactive where Base == ChannelPresenter {
    
    var repliesRequest: Observable<[Message]> {
        prepareRequest()
            .filter { [weak base] in $0 != .none && base?.parentMessage != nil }
            .flatMapLatest { [weak base] in (base?.parentMessage?.rx.replies(pagination: $0) ?? .empty()).retry(3) }
    }
    
    var webSocketEvents: Driver<ViewChanges> {
        Client.shared.rx.events(cid: base.channel.cid)
            .filter({ [weak base] event in
                if let eventsFilter = base?.eventsFilter {
                    return eventsFilter(event, base?.channel)
                }
                
                return true
            })
            .map { [weak base] in base?.parse(event: $0) ?? .none }
            .filter { $0 != .none }
            .map { [weak base] in base?.mapWithEphemeralMessage($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError($0))) }
    }
    
    var ephemeralMessageEvents: Driver<ViewChanges> {
        base.ephemeralSubject
            .skip(1)
            .map { [weak base] in base?.parseEphemeralMessageEvents($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError($0))) }
    }
    
    func parsedRepliesResponse(_ repliesResponse: Observable<[Message]>) -> Driver<ViewChanges> {
        repliesResponse
            .map { [weak base] in base?.parse(replies: $0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError($0))) }
    }
}
