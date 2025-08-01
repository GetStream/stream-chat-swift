//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import Foundation

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

extension ImageProcessors {
    /// Rounds the corners of an image to the specified radius.
    ///
    /// - important: In order for the corners to be displayed correctly, the image must exactly match the size
    /// of the image view in which it will be displayed. See ``ImageProcessors/Resize`` for more info.
    struct RoundedCorners: ImageProcessing, Hashable, CustomStringConvertible {
        private let radius: CGFloat
        private let border: ImageProcessingOptions.Border?

        /// Initializes the processor with the given radius.
        ///
        /// - parameters:
        ///   - radius: The radius of the corners.
        ///   - unit: Unit of the radius.
        ///   - border: An optional border drawn around the image.
        init(radius: CGFloat, unit: ImageProcessingOptions.Unit = .points, border: ImageProcessingOptions.Border? = nil) {
            self.radius = radius.converted(to: unit)
            self.border = border
        }

        func process(_ image: PlatformImage) -> PlatformImage? {
            image.processed.byAddingRoundedCorners(radius: radius, border: border)
        }

        var identifier: String {
            let suffix = border.map { ",border=\($0)" }
            return "com.github.kean/nuke/rounded_corners?radius=\(radius)" + (suffix ?? "")
        }

        var description: String {
            "RoundedCorners(radius: \(radius) pixels, border: \(border?.description ?? "nil"))"
        }
    }
}
