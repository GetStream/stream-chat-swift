//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

protocol SkeletonLoadable {
    func makeAnimationGroup(previousGroup: CAAnimationGroup?) -> CAAnimationGroup
}

extension SkeletonLoadable where Self: AppearanceProvider {
    func makeAnimationGroup(previousGroup: CAAnimationGroup? = nil) -> CAAnimationGroup {
        let animDuration: CFTimeInterval = 1.5
        let animation1 = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.backgroundColor))
        animation1.fromValue = appearance.colorPalette.background2.cgColor
        animation1.toValue = appearance.colorPalette.background7.cgColor
        animation1.duration = animDuration
        animation1.beginTime = 0.0

        let animation2 = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.backgroundColor))
        animation2.fromValue = appearance.colorPalette.background7.cgColor
        animation2.toValue = appearance.colorPalette.background2.cgColor
        animation2.duration = animDuration
        animation2.beginTime = animation1.beginTime + animation1.duration

        let group = CAAnimationGroup()
        group.animations = [animation1, animation2]
        group.repeatCount = .greatestFiniteMagnitude // infinite
        group.duration = animation2.beginTime + animation2.duration
        group.isRemovedOnCompletion = false

        if let previousGroup = previousGroup {
            // Offset groups by 0.33 seconds for effect
            group.beginTime = previousGroup.beginTime + 0.33
        }

        return group
    }
}
