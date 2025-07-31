//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace with all available encoders.
enum ImageEncoders {}

extension ImageEncoding where Self == ImageEncoders.Default {
    static func `default`(compressionQuality: Float = 0.8) -> ImageEncoders.Default {
        ImageEncoders.Default(compressionQuality: compressionQuality)
    }
}

extension ImageEncoding where Self == ImageEncoders.ImageIO {
    static func imageIO(type: AssetType, compressionRatio: Float = 0.8) -> ImageEncoders.ImageIO {
        ImageEncoders.ImageIO(type: type, compressionRatio: compressionRatio)
    }
}
