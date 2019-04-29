//
//  UIView+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 29/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIView {
    
    @discardableResult
    func systemLayoutHeightToFit() -> UIView {
        setNeedsLayout()
        layoutIfNeeded()
        var frame = self.frame
        frame.size.height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        self.frame = frame
        return self
    }
    
    static func animateSmooth(withDuration duration: TimeInterval, animations: @escaping () -> Void) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0,
                       options: .curveLinear,
                       animations: animations)
    }
    
    static func animateSmooth(withDuration duration: TimeInterval,
                              animations: @escaping () -> Void,
                              completion: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0,
                       options: .curveLinear,
                       animations: animations,
                       completion: completion)
    }
}
