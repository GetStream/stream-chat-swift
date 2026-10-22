//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import simd
import UIKit

// Turns colors into the HSV the shaders read, keeping their full hue, saturation and value so
// muted and pastel brand colors render true.
enum VoiceVisualizationPalette {
    static let maximumCount = 5

    static func hsv(_ colors: [UIColor], traits: UITraitCollection) -> [SIMD3<Float>] {
        colors.prefix(maximumCount).map { hsv($0.resolvedColor(with: traits)) }
    }

    // Hue as a fraction of a turn, saturation and value, each from 0 to 1.
    static func hsv(_ color: UIColor) -> SIMD3<Float> {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var value: CGFloat = 0
        var alpha: CGFloat = 0
        if !color.getHue(&hue, saturation: &saturation, brightness: &value, alpha: &alpha) {
            var white: CGFloat = 0
            if color.getWhite(&white, alpha: &alpha) {
                value = white
            }
        }
        let turn = Float(hue).truncatingRemainder(dividingBy: 1)
        return SIMD3(
            turn < 0 ? turn + 1 : turn,
            Float(min(max(saturation, 0), 1)),
            Float(min(max(value, 0), 1))
        )
    }
}
