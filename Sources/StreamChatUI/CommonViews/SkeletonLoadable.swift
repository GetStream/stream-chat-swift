//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

protocol SkeletonLoadable {}

extension SkeletonLoadable {
    func makeAnimationGroup(previousGroup: CAAnimationGroup? = nil) -> CAAnimationGroup {
        let animDuration: CFTimeInterval = 1.5
        let animation1 = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.backgroundColor))
        animation1.fromValue = Appearance.ColorPalette().background2.cgColor
        animation1.toValue = Appearance.ColorPalette().background7.cgColor
        animation1.duration = animDuration
        animation1.beginTime = 0.0

        let animation2 = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.backgroundColor))
        animation2.fromValue = Appearance.ColorPalette().background7.cgColor
        animation2.toValue = Appearance.ColorPalette().background2.cgColor
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
