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
}

/// MARK: - Safe Area Layout Guide

extension UIView {
    
    var safeAreaTopOffset: CGFloat {
        return safeAreaLayoutGuide.layoutFrame.origin.y
    }
    
    var safeAreaBottomOffset: CGFloat {
        return UIScreen.main.bounds.height - safeAreaLayoutGuide.layoutFrame.height - safeAreaLayoutGuide.layoutFrame.origin.y
    }
}

/// MARK: - Animations

extension UIView {
    
    static func animateSmooth(withDuration duration: TimeInterval,
                              usingSpringWithDamping dampingRatio: CGFloat = 1,
                              animations: @escaping () -> Void) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: dampingRatio,
                       initialSpringVelocity: 0,
                       options: .curveLinear,
                       animations: animations)
    }
    
    static func animateSmooth(withDuration duration: TimeInterval,
                              usingSpringWithDamping dampingRatio: CGFloat = 1,
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
