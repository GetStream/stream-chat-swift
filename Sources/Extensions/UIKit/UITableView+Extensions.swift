//
//  UITableView+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 26/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UITableView {
    
    var bottomContentOffset: CGFloat {
        return contentSize.height - (contentOffset.y + frame.height - contentInset.bottom - contentInset.top)
    }
    
    func update(_ transaction: () -> Void) {
        beginUpdates()
        transaction()
        endUpdates()
        layoutIfNeeded()
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
