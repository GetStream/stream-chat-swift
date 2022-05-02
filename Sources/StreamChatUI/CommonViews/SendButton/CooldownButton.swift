//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// A button for showing a cooldown when Slow Mode is active.
open class CooldownButton: _Button, AppearanceProvider {
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()

        isEnabled = false
        clipsToBounds = true
        backgroundColor = appearance.colorPalette.alternativeInactiveTint
        titleLabel?.font = appearance.fonts.bodyBold
        titleLabel?.adjustsFontForContentSizeCategory = true
    }
    
    func start(with cooldown: Int, onChange: @escaping (Int) -> Void) {
        if cooldown > 0 {
            var duration = cooldown
            let timer = Timer.scheduledTimer(
                withTimeInterval: 1,
                repeats: true
            ) { [weak self] timer in
                guard let self = self else { return }
                onChange(duration)
                
                if duration == 0 {
                    timer.invalidate()
                } else {
                    self.setTitle("\(duration)", for: .disabled)
                    duration -= 1
                }
            }
            
            RunLoop.current.add(timer, forMode: .common)
            timer.fire()
        }
    }
}
