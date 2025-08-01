//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

enum ImageDecompression {
    static func isDecompressionNeeded(for response: ImageResponse) -> Bool {
        isDecompressionNeeded(for: response.image) ?? false
    }

    static func decompress(image: PlatformImage, isUsingPrepareForDisplay: Bool = false) -> PlatformImage {
        image.decompressed(isUsingPrepareForDisplay: isUsingPrepareForDisplay) ?? image
    }

    // MARK: Managing Decompression State

    #if swift(>=5.10)
    // Safe because it's never mutated.
    nonisolated(unsafe) static let isDecompressionNeededAK = malloc(1)!
    #else
    static let isDecompressionNeededAK = malloc(1)!
    #endif

    static func setDecompressionNeeded(_ isDecompressionNeeded: Bool, for image: PlatformImage) {
        objc_setAssociatedObject(image, isDecompressionNeededAK, isDecompressionNeeded, .OBJC_ASSOCIATION_RETAIN)
    }

    static func isDecompressionNeeded(for image: PlatformImage) -> Bool? {
        objc_getAssociatedObject(image, isDecompressionNeededAK) as? Bool
    }
}
