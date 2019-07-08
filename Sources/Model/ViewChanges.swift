//
//  ViewChanges.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 16/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view changes.
///
/// ViewChanges describes how a view should be updated depends on a data response.
public enum ViewChanges: Equatable {
    case none
    case reloaded(_ row: Int, _ items: [ChatItem])
    case itemAdded(_ row: Int, _ reloadRow: Int?, _ forceToScroll: Bool, _ items: [ChatItem])
    case itemUpdated(_ rows: [Int], [Message], _ items: [ChatItem])
    case itemRemoved(_ row: Int, _ items: [ChatItem])
    case itemMoved(fromRow: Int, toRow: Int, _ items: [ChatItem])
    case footerUpdated
}

extension ViewChanges: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "<none>"
        case let .reloaded(row, items):
            return "<reloaded\(items.count): \(row)>"
        case let .itemAdded(row, reloadRow, _, items):
            return "<itemAdded\(items.count): \(row) -> \(reloadRow ?? -1)>"
        case let .itemUpdated(rows, messages, items):
            return "<itemUpdated\(items.count): \(rows)> \(messages.map({ $0.textOrArgs}).joined(separator: ", "))"
        case let .itemRemoved(row, items):
            return "<itemRemoved\(items.count): \(row)>"
        case let .itemMoved(fromRow, toRow, items):
            return "<itemMoved\(items.count): \(fromRow) -> \(toRow)>"
        case .footerUpdated:
            return "<footerUpdated>"
        }
    }
}
