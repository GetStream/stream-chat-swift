//
//  UITableView+Reusable.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 08/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITableView {
    
    final func register<T: UITableViewCell>(cellType: T.Type) where T: Reusable {
        register(cellType.self, forCellReuseIdentifier: cellType.reuseIdentifier)
    }
    
    final func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath, cellType: T.Type = T.self) -> T where T: Reusable {
        guard let cell = self.dequeueReusableCell(withIdentifier: cellType.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Failed to dequeue a cell with identifier \(cellType.reuseIdentifier) matching type \(cellType.self).")
        }
        
        return cell
    }
    
    final func registerMessageCell(style: MessageViewStyle) {
        register(MessageTableViewCell.self,
                 forCellReuseIdentifier: reuseIdentifier(cellType: MessageTableViewCell.self, style: style))
    }
    
    final func dequeueMessageCell(for indexPath: IndexPath, style: MessageViewStyle) -> MessageTableViewCell {
        let identifier = reuseIdentifier(cellType: MessageTableViewCell.self, style: style)
        
        guard let cell = self.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MessageTableViewCell else {
            fatalError("Failed to dequeue a cell with identifier \(identifier) matching type MessageTableViewCell.")
        }
        
        cell.setupIfNeeded(style: style)
        return cell
    }
    
    private func reuseIdentifier(cellType: MessageTableViewCell.Type, style: MessageViewStyle) -> String {
        return cellType.reuseIdentifier.appending("_").appending(String(style.hashValue))
    }
}
