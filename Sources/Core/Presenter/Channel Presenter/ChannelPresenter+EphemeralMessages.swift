//
//  ChannelPresenter+EphemeralMessages.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Ephemeral Messages

extension ChannelPresenter {
    
    func parseEphemeralMessageEvents(_ ephemeralType: EphemeralType) -> ViewChanges {
        if let message = ephemeralType.message {
            var items = self.items
            let row = items.count
            items.append(.message(message, []))
            
            if ephemeralType.updated {
                return .itemUpdated([row], [message], items)
            }
            
            return .itemAdded(row, nil, true, items)
        }
        
        return .itemRemoved(items.count, items)
    }
    
    func mapWithEphemeralMessage(_ changes: ViewChanges) -> ViewChanges {
        guard let ephemeralType = try? ephemeralSubject.value(), let ephemeralMessage = ephemeralType.message else {
            return changes
        }
        
        switch changes {
        case .none, .footerUpdated, .error:
            return changes
            
        case let .reloaded(row, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .reloaded(row, items)
            
        case let .itemAdded(row, reloadRow, forceToScroll, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemAdded(row, reloadRow, forceToScroll, items)
            
        case let .itemUpdated(row, message, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemUpdated(row, message, items)
            
        case let .itemRemoved(row, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemRemoved(row, items)
            
        case let .itemMoved(fromRow, toRow, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemMoved(fromRow: fromRow, toRow: toRow, items)
            
        case .disconnected:
            return .none
        }
    }
}

// MARK: - Ephemeral Message Actions

extension ChannelPresenter {
    /// Dispatch an ephemeral message action, e.g. shuffle, send.
    public func dispatch(action: Attachment.Action, message: Message) -> Observable<MessageResponse> {
        if action.isCancelled || action.isSend {
            ephemeralSubject.onNext((nil, true))
            
            if action.isCancelled {
                return .empty()
            }
        }
        
        return channel.send(action: action, for: message)
            .do(onNext: { [weak self] in self?.updateEphemeralMessage($0.message) })
            .observeOn(MainScheduler.instance)
    }
    
    func updateEphemeralMessage(_ message: Message) {
        if message.type == .ephemeral {
            ephemeralSubject.onNext((message, hasEphemeralMessage))
        }
    }
}
