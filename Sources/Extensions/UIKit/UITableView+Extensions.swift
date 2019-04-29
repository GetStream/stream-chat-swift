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
    
    func scrollToBottom(animated: Bool = true) {
        let offset = contentSize.height - (frame.height - contentInset.bottom - contentInset.top)
        setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
    }
    
    func layoutFooterView() {
        tableFooterView = tableFooterView?.systemLayoutHeightToFit()
    }
}
