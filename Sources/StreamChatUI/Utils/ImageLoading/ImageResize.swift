//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// The resize information when loading an image.
public struct ImageResize {
    /// The new width of the image in points (not pixels).
    public var width: CGFloat
    /// The new height of the image in points (not pixels).
    public var height: CGFloat
    /// The resize content mode.
    public var mode: Mode

    /// The resize information when loading an image.
    ///
    /// - Parameters:
    ///   - size: The new size of the image in points (not pixels).
    ///   - mode: The resize content mode.
    public init(_ size: CGSize, mode: Mode = .clip) {
        width = size.width
        height = size.height
        self.mode = mode
    }
}

extension ImageResize {
    /// The way to resize the image. The default value is `clip`.
    ///
    /// The possible options:
    /// - `clip`
    /// - `crop`
    /// - `fill`
    /// - `scale`
    public struct Mode {
        public var value: String
        public var cropValue: String?

        init(value: String, cropValue: String? = nil) {
            self.value = value
            self.cropValue = cropValue
        }

        /// Make the image as large as possible, while maintaining aspect ratio and keeping the
        /// height and width less than or equal to the given height and width.
        public static var clip = Mode(value: "clip")

        /// Crop to the given dimensions, keeping focus on the portion of the image in the crop mode.
        public static func crop(_ value: Crop = .center) -> Self {
            Mode(value: "crop", cropValue: value.rawValue)
        }

        /// Make the image as large as possible, while maintaining aspect ratio and keeping the height and width
        /// less than or equal to the given height and width. Fill any leftover space with a black background.
        public static var fill = Mode(value: "fill")

        /// Ignore aspect ratio, and resize the image to the given height and width.
        public static var scale = Mode(value: "scale")

        /// The crop position of the image.
        public enum Crop: String {
            case top
            case bottom
            case right
            case left
            case center
        }
    }
}
