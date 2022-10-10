//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

/// The options for loading an image.
public struct ImageLoaderOptions {
    // Ideally, the name would be `ImageLoadingOptions`, but this would conflict with Nuke.

    /// The placeholder to be used while the image is finishing loading.
    public var placeholder: UIImage?
    /// The resize information when loading an image. `Nil` if you want the full resolution of the image.
    public var resize: Resize?

    public init(placeholder: UIImage?, resize: Resize?) {
        self.placeholder = placeholder
        self.resize = resize
    }
}

extension ImageLoaderOptions {
    /// The resize information when loading an image.
    public struct Resize {
        public var width: CGFloat
        public var height: CGFloat
        public var mode: ResizeMode

        public init(width: CGFloat, height: CGFloat, mode: ResizeMode = .clip) {
            self.width = width
            self.height = height
            self.mode = mode
        }
    }

    /// The way to resize the image. The default value is `clip`.
    ///
    /// The possible options:
    /// - `clip`
    /// - `crop`
    /// - `fill`
    /// - `scale`
    public struct ResizeMode {
        internal var modeValue: String
        internal var cropValue: String?

        internal init(modeValue: String, cropValue: String? = nil) {
            self.modeValue = modeValue
            self.cropValue = cropValue
        }

        /// Make the image as large as possible, while maintaining aspect ratio and keeping the
        /// height and width less than or equal to the given height and width.
        public static var clip = ResizeMode(modeValue: "crop")

        /// Crop to the given dimensions, keeping focus on the portion of the image in the crop mode.
        public static func crop(_ value: Crop = .center) -> Self {
            ResizeMode(modeValue: "crop", cropValue: value.rawValue)
        }

        /// Make the image as large as possible, while maintaining aspect ratio and keeping the height and width
        /// less than or equal to the given height and width. Fill any leftover space with a black background.
        public static var fill = ResizeMode(modeValue: "fill")

        /// Ignore aspect ratio, and resize the image to the given height and width.
        public static var scale = ResizeMode(modeValue: "scale")

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
