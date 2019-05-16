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
    case reloaded(_ row: Int, UITableView.ScrollPosition)
    case itemAdded(_ row: Int, _ reloadRow: Int?, _ forceToScroll: Bool)
    case itemUpdated(_ row: Int, Message)
    case itemRemoved(_ row: Int)
    case itemMoved(fromRow: Int, toRow: Int)
    case footerUpdated(_ isUsersTyping: Bool)
}
