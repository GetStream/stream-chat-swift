//
//  UIView+Extensions.swift
//  StreamChat
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
    
    func makeEdgesEqualToSuperview(superview parent: UIView? = nil) {
        parent?.addSubview(self)
        
        guard superview != nil else {
            print("⚠️ Can't add layout constraints: superview is nil", #function)
            return
        }
        
        snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    func makeCenterEqualToSuperview(superview parent: UIView? = nil) {
        parent?.addSubview(self)
        
        guard superview != nil else {
            print("⚠️ Can't add layout constraints: superview is nil", #function)
            return
        }
        
        snp.makeConstraints { $0.center.equalToSuperview() }
    }
    
    func makeEdgesEqualToSafeAreaSuperview(superview parent: UIView? = nil) {
        parent?.addSubview(self)
        
        guard let parent = superview else {
            print("⚠️ Can't add layout constraints: superview is nil", #function)
            return
        }
        
        snp.makeConstraints {
            $0.top.equalTo(parent.safeAreaLayoutGuide.snp.topMargin)
            $0.bottom.equalTo(parent.safeAreaLayoutGuide.snp.bottomMargin)
            $0.left.equalTo(parent.safeAreaLayoutGuide.snp.leftMargin)
            $0.right.equalTo(parent.safeAreaLayoutGuide.snp.rightMargin)
        }
    }
    
    func sendToBack(for subviews: [UIView]) {
        guard let parent = superview else {
            return
        }
        
        parent.sendSubviewToBack(self, for: subviews)
    }
    
    func sendSubviewToBack(_ subview: UIView, for subviews: [UIView]) {
        guard let subviewIndex = self.subviews.firstIndex(of: subview) else {
            return
        }
        
        var newIndex = subviewIndex
        
        subviews.forEach { other in
            if let index = self.subviews.firstIndex(of: other) {
                newIndex = min(newIndex, index)
            }
        }
        
        if newIndex != subviewIndex {
            exchangeSubview(at: subviewIndex, withSubviewAt: newIndex)
        }
    }
}

// MARK: - Safe Area Layout Guide

extension UIView {
    
    var safeAreaTopOffset: CGFloat {
        return safeAreaLayoutGuide.layoutFrame.origin.y
    }
    
    var safeAreaBottomOffset: CGFloat {
        return UIScreen.main.bounds.height - safeAreaLayoutGuide.layoutFrame.height - safeAreaLayoutGuide.layoutFrame.origin.y
    }
}

// MARK: - Animations

extension UIView {
    func removeAllAnimations() {
        CATransaction.begin()
        layer.removeAllAnimations()
        CATransaction.commit()
    }
}

// MARK: - Smooth and Chain animations

extension UIView {
    typealias Animations = () -> Void
    typealias AnimationsCompletion = (_ finished: Bool) -> Void
    
    final class Chain {
        private let duration: TimeInterval
        private let dampingRatio: CGFloat
        private let velocity: CGFloat
        private let options: AnimationOptions
        private let animations: Animations
        private var completion: AnimationsCompletion?
        private var next: Chain?
        
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
    static func animateSmoothly(withDuration duration: TimeInterval,
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
    
    static func animateSmoothly(withDuration duration: TimeInterval,
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
    
    static func layerAnimated(_ animated: Bool, _ block: () -> Void) {
        if animated {
            block()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            block()
            CATransaction.commit()
            CATransaction.setDisableActions(false)
        }
    }
}
