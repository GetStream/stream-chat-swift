// The MIT License (MIT)
//
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

import Foundation

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

extension ImageEncoders {
    /// A default adaptive encoder which uses best encoder available depending
    /// on the input image and its configuration.
    struct Default: ImageEncoding {
        var compressionQuality: Float

        /// Set to `true` to switch to HEIF when it is available on the current hardware.
        /// `false` by default.
        var isHEIFPreferred = false

        init(compressionQuality: Float = 0.8) {
            self.compressionQuality = compressionQuality
        }

        func encode(_ image: PlatformImage) -> Data? {
            guard let cgImage = image.cgImage else {
                return nil
            }
            let type: AssetType
            if cgImage.isOpaque {
                if isHEIFPreferred && ImageEncoders.ImageIO.isSupported(type: .heic) {
                    type = .heic
                } else {
                    type = .jpeg
                }
            } else {
                type = .png
            }
            let encoder = ImageEncoders.ImageIO(type: type, compressionRatio: compressionQuality)
            return encoder.encode(image)
        }
    }
}
