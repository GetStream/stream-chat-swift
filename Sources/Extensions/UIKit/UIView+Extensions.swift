//
//  UIView+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 29/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

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
    
    func edgesEqualToSuperview() {
        snp.makeConstraints { $0.edges.equalToSuperview() }
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

/// MARK: - Smooth and Chain animations

extension UIView {
    typealias Animations = () -> Void
    typealias AnimationsCompletion = (_ finished: Bool) -> Void
    
    final class Chain {
        private let duration: TimeInterval
        private let dampingRatio: CGFloat
        private let velocity: CGFloat
        private let options: AnimationOptions
        private let animations: Animations
        private var completion: AnimationsCompletion? = nil
        private var next: Chain? = nil
        
        init(duration: TimeInterval,
             dampingRatio: CGFloat,
             velocity: CGFloat,
             options: AnimationOptions = [],
             animations: @escaping Animations) {
            self.duration = duration
            self.dampingRatio = dampingRatio
            self.velocity = velocity
            self.options = options
            self.animations = animations
        }
        
        @discardableResult
        func then(duration: TimeInterval,
                  dampingRatio: CGFloat = 1,
                  initialSpringVelocity velocity: CGFloat = 0,
                  options: AnimationOptions = [],
                  animations: @escaping Animations) -> Chain {
            let next = Chain(duration: duration,
                             dampingRatio: dampingRatio,
                             velocity: velocity,
                             options: options,
                             animations: animations)
            
            self.next = next
            return next
        }
        
        func finish(with completion: @escaping AnimationsCompletion) {
            self.completion = completion
        }
        
        deinit {
            let next = self.next
            let completion = self.completion
            
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: dampingRatio,
                           initialSpringVelocity: velocity,
                           options: (dampingRatio != 1 && options == [] ? .curveLinear : options),
                           animations: animations) { [next] finished in
                            if next == nil {
                                completion?(finished)
                            }
            }
        }
    }
    
    @discardableResult
    static func animateSmooth(withDuration duration: TimeInterval,
                              usingSpringWithDamping dampingRatio: CGFloat = 1,
                              initialSpringVelocity velocity: CGFloat = 0,
                              options: AnimationOptions = [],
                              animations: @escaping Animations) -> Chain {
        return Chain(duration: duration,
                     dampingRatio: dampingRatio,
                     velocity: velocity,
                     options: options,
                     animations: animations)
    }
    
    static func animateSmooth(withDuration duration: TimeInterval,
                              delay: TimeInterval = 0,
                              usingSpringWithDamping dampingRatio: CGFloat = 1,
                              initialSpringVelocity velocity: CGFloat = 0,
                              options: AnimationOptions = [],
                              animations: @escaping Animations,
                              completion: @escaping AnimationsCompletion) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: dampingRatio,
                       initialSpringVelocity: velocity,
                       options: (dampingRatio != 1 && options == [] ? .curveLinear : options),
                       animations: animations,
                       completion: completion)
    }
}
