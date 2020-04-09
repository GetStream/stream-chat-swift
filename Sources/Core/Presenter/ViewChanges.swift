//
//  ViewChanges.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 16/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient

/// A view changes.
///
/// ViewChanges describes how a view should be updated depends on a data response.
public enum ViewChanges: Equatable, Decodable {
    
    /// No changes.
    case none
    /// Reload all views.
    case reloaded(_ scrollToRow: Int, _ items: [PresenterItem])
    /// Add item at row and reload another one.
    case itemsAdded(_ rows: [Int], _ reloadRow: Int?, _ forceToScroll: Bool, _ items: [PresenterItem])
    /// Update items with messages.
    case itemsUpdated(_ rows: [Int], [Message], _ items: [PresenterItem])
    /// Remove item at row.
    case itemRemoved(_ row: Int, _ items: [PresenterItem])
    /// Move item from row to another.
    case itemMoved(fromRow: Int, toRow: Int, _ items: [PresenterItem])
    /// Update fiiter.
    case footerUpdated
    /// Disconnected deliberately.
    case disconnected
    /// Error message.
    case error(ClientError)
    
    public init(from decoder: Decoder) throws {
        self = .none
    }
}

extension ViewChanges: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "<none>"
        case let .reloaded(row, items):
            return "<reloaded\(items.count): \(row)>"
        case let .itemsAdded(rows, reloadRow, _, items):
            return "<itemsAdded\(items.count): \(rows) -> \(reloadRow ?? -1)>"
        case let .itemsUpdated(rows, messages, items):
            return "<itemsUpdated\(items.count): \(rows)> \(messages.map({ $0.textOrArgs }).joined(separator: ", "))"
        case let .itemRemoved(row, items):
            return "<itemRemoved\(items.count): \(row)>"
        case let .itemMoved(fromRow, toRow, items):
            return "<itemMoved\(items.count): \(fromRow) -> \(toRow)>"
        case .footerUpdated:
            return "<footerUpdated>"
        case .disconnected:
            return "<disconnected deliberately>"
        case .error(let error):
            return "<error: \(error)>"
        }
    }
}
