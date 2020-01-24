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
    
    /// Scroll a table view to the last bottom cell.
    ///
    /// - Parameter animated: true if you want to animate the change in position; false if it should be immediate.
    public func scrollToBottom(animated: Bool = true) {
        scrollToRowIfPossible(at: Int.max, animated: animated)
    }
    
    public func scrollToRowIfPossible(at row: Int, animated: Bool = true) {
        let sectionsCount = numberOfSections
        
        guard sectionsCount > 0 else {
            return
        }
        
        let rowsCount = numberOfRows(inSection: (sectionsCount - 1))
        
        guard rowsCount > 0 else {
            return
        }
        
        let row: Int = min(row, rowsCount - 1)
        setContentOffset(contentOffset, animated: false)
        scrollToRow(at: IndexPath(row: row, section: sectionsCount - 1), at: .top, animated: animated)
    }
    
    func layoutFooterView() {
        tableFooterView = tableFooterView?.systemLayoutHeightToFit()
    }
}

// MARK: - Cells

extension UITableView {
    /// A loading cell title.
    public static var loadingTitle = "Loading..."
    
    /// A default loading table view cell.
    ///
    /// - Parameters:
    ///   - indexPath: an index path.
    ///   - textColor: a text color of the status.
    /// - Returns: a loading table view cell.
    public func loadingCell(at indexPath: IndexPath, textColor: UIColor = .chatGray) -> UITableViewCell {
        return statusCell(at: indexPath, title: TableView.loadingTitle, textColor: textColor)
    }
    
    /// A default status table view cell.
    ///
    /// - Parameters:
    ///   - indexPath: an index path.
    ///   - title: a title.
    ///   - subtitle: a subtitle.
    ///   - textColor: a text color of the status.
    /// - Returns: a status table view cell.
    public func statusCell(at indexPath: IndexPath,
                           title: String,
                           subtitle: String? = nil,
                           textColor: UIColor = .chatGray) -> UITableViewCell {
        let cell = dequeueReusableCell(for: indexPath, cellType: StatusTableViewCell.self) as StatusTableViewCell
        cell.backgroundColor = backgroundColor
        cell.update(title: title, subtitle: subtitle, textColor: textColor)
        return cell
    }
}
