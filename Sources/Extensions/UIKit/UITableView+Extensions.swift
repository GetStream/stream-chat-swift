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
}
