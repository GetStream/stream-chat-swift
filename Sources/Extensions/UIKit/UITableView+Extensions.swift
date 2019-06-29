//
//  UITableView+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 26/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITableView {
    
    var bottomContentOffset: CGFloat {
        return contentSize.height - (contentOffset.y + frame.height - contentInset.bottom - contentInset.top)
    }
    
    /// Scroll to bottom.
    public func scrollToBottom(animated: Bool = true) {
        let sectionsCount = numberOfSections
        
        guard sectionsCount > 0 else {
            return
        }
        
        let rowsCount = numberOfRows(inSection: (sectionsCount - 1))
        
        guard rowsCount > 0 else {
            return
        }
        
        setContentOffset(contentOffset, animated: false)
        scrollToRow(at: IndexPath(row: rowsCount - 1, section: sectionsCount - 1), at: .top, animated: animated)
    }
    
    func layoutFooterView() {
        tableFooterView = tableFooterView?.systemLayoutHeightToFit()
    }
}

// MARK: - Cells

extension UITableView {
    public static var loadingTitle = "Loading..."
    
    public func loadingCell(at indexPath: IndexPath, backgroundColor: UIColor) -> UITableViewCell {
        return statusCell(at: indexPath, title: UITableView.loadingTitle, backgroundColor: backgroundColor, highlighted: false)
    }
    
    public func statusCell(at indexPath: IndexPath,
                           title: String,
                           subtitle: String? = nil,
                           backgroundColor: UIColor,
                           highlighted: Bool) -> UITableViewCell {
        let cell = dequeueReusableCell(for: indexPath, cellType: StatusTableViewCell.self) as StatusTableViewCell
        cell.backgroundColor = backgroundColor
        cell.update(title: title, subtitle: subtitle, highlighted: highlighted)
        return cell
    }
}
