//
//  ViewChanges.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 16/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

public enum ViewChanges: Equatable {
    case none
    case reloaded(_ row: Int, UITableView.ScrollPosition, _ items: [ChatItem])
    case itemAdded(_ row: Int, _ reloadRow: Int?, _ forceToScroll: Bool, _ items: [ChatItem])
    case itemUpdated(_ row: Int, Message, _ items: [ChatItem])
    case itemRemoved(_ row: Int, _ items: [ChatItem])
    case itemMoved(fromRow: Int, toRow: Int, _ items: [ChatItem])
    case footerUpdated(_ isUsersTyping: Bool)
}

extension ViewChanges: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "<none>"
        case let .reloaded(row, _, items):
            return "<reloaded\(items.count): \(row)>"
        case let .itemAdded(row, reloadRow, _, items):
            return "<itemAdded\(items.count): \(row) -> \(reloadRow ?? -1)>"
        case let .itemUpdated(row, message, items):
            return "<itemUpdated\(items.count): \(row)> \(message.textOrArgs)"
        case let .itemRemoved(row, items):
            return "<itemRemoved\(items.count): \(row)>"
        case let .itemMoved(fromRow, toRow, items):
            return "<itemMoved\(items.count): \(fromRow) -> \(toRow)>"
        case .footerUpdated(let isUsersTyping):
            return "<footerUpdated: typing=\(isUsersTyping)>"
        }
    }
}
