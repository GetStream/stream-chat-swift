//
//  UITableView+Reusable.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 08/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITableView {
    final func registerMessageCell(style: MessageViewStyle) {
        register(MessageTableViewCell.self, forCellReuseIdentifier: reuseIdentifier(cellType: MessageTableViewCell.self, style: style))
    }
    
    final func dequeueMessageCell(for indexPath: IndexPath, style: MessageViewStyle) -> MessageTableViewCell {
        let identifier = reuseIdentifier(cellType: MessageTableViewCell.self, style: style)
        
        guard let cell = self.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? MessageTableViewCell else {
            fatalError("Failed to dequeue a cell with identifier \(identifier) matching type MessageTableViewCell.")
        }
        
        if cell.style == nil {
            cell.style = style
        }
        
        return cell
    }
    
    private func reuseIdentifier(cellType: MessageTableViewCell.Type, style: MessageViewStyle) -> String {
        return cellType.reuseIdentifier.appending("_").appending(String(style.hashValue))
    }
}
