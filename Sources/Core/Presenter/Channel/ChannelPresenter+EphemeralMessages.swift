//
//  ChannelPresenter+EphemeralMessages.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: - Ephemeral Messages

extension ChannelPresenter {
    
    func parseEphemeralMessageEvents(_ ephemeralType: EphemeralType) -> ViewChanges {
        if let message = ephemeralType.message {
            var items = self.items
            let row = items.count
            items.append(.message(message, []))
            
            if ephemeralType.updated {
                return .itemsUpdated([row], [message], items)
            }
            
            return .itemsAdded([row], nil, true, items)
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
            
        case let .itemsAdded(rows, reloadRow, forceToScroll, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemsAdded(rows, reloadRow, forceToScroll, items)
            
        case let .itemsUpdated(rows, message, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemsUpdated(rows, message, items)
            
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
    /// - Parameters:
    ///   - action: an attachment action for the ephemeral message.
    ///   - message: an ephemeral message
    ///   - completion: a completion block with `MessageResponse`.
    public func dispatchEphemeralMessageAction(_ action: Attachment.Action,
                                               message: Message,
                                               _ completion: @escaping Client.Completion<MessageResponse>) {
        rx.dispatchEphemeralMessageAction(action, message: message).bindOnce(to: completion)
    }
    
    func updateEphemeralMessage(_ message: Message) {
        if message.type == .ephemeral {
            ephemeralSubject.onNext((message, hasEphemeralMessage))
        }
    }
}
