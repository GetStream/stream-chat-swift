//
//  TableView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 24/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

/// A custom chat table view.
public final class TableView: UITableView {
    
    private var oldContentSize: CGSize = .zero
    private var oldContentOffset: CGPoint = .zero
    private(set) var oldContentInset: UIEdgeInsets = .zero
    private(set) var oldAdjustedContentInset: UIEdgeInsets = .zero
    
    var stayOnScrollOnce = false {
        didSet {
            if stayOnScrollOnce {
                saveScrollState()
            }
        }
    }
    
    override public func layoutSubviews() {
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
    
    func saveContentInsetState() {
        guard oldContentInset == .zero, oldAdjustedContentInset == .zero else {
            return
        }
        
        oldContentInset = contentInset
        oldAdjustedContentInset = adjustedContentInset
    }
    
    func resetContentInsetState() {
        oldContentInset = .zero
        oldAdjustedContentInset = .zero
    }
}
