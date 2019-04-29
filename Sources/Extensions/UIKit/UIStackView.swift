//
//  UIStackView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 29/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIStackView {
    /// Find an arranged subview type of T.
    func findArrangedSubview<T>(typeOf: T.Type, tag: Int = 0) -> T? where T: UIView {
        guard !arrangedSubviews.isEmpty else {
            return nil
        }
        
        return arrangedSubviews.first(where: { $0 is T && $0.tag == tag }) as? T
    }
    
    /// Find and remove arranged subview type of T.
    func removeArrangedSubview<T>(typeOf: T.Type, tag: Int = 0) where T: UIView {
        guard !arrangedSubviews.isEmpty else {
            return
        }
        
        if let existsArrangedSubview = findArrangedSubview(typeOf: T.self, tag: tag) {
            removeArrangedSubview(existsArrangedSubview)
            existsArrangedSubview.removeFromSuperview()
        }
    }
}
