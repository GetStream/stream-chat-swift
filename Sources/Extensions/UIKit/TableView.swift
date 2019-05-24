//
//  TableView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 24/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

final class TableView: UITableView {
    
    private var oldContentSize: CGSize = .zero
    private var oldContentOffset: CGPoint = .zero
    
    var stayOnScrollOnce = false {
        didSet {
            if stayOnScrollOnce {
                saveScrollState()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if stayOnScrollOnce, oldContentSize.height != contentSize.height {
            stayOnScrollOnce = false
            restoreScrollState()
        }
    }
    
    func saveScrollState() {
        setContentOffset(contentOffset, animated: false)
        oldContentSize = contentSize
        oldContentOffset = contentOffset
    }
    
    func restoreScrollState(animated: Bool = false) {
        let dHeight = contentSize.height - oldContentSize.height
        let scrollPoint = CGPoint(x: 0, y: oldContentOffset.y + dHeight)
        setContentOffset(scrollPoint, animated: animated)
    }
}
