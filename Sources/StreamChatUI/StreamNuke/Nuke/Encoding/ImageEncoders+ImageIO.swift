//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import Foundation
import ImageIO

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

extension ImageEncoders {
    /// An Image I/O based encoder.
    ///
    /// Image I/O is a system framework that allows applications to read and
    /// write most image file formats. This framework offers high efficiency,
    /// color management, and access to image metadata.
    struct ImageIO: ImageEncoding {
        let type: AssetType
        let compressionRatio: Float

        /// - parameter format: The output format. Make sure that the format is
        /// supported on the current hardware.s
        /// - parameter compressionRatio: 0.8 by default.
        init(type: AssetType, compressionRatio: Float = 0.8) {
            self.type = type
            self.compressionRatio = compressionRatio
        }

        private static let availability = NukeAtomic<[AssetType: Bool]>(value: [:])

        /// Returns `true` if the encoding is available for the given format on
        /// the current hardware. Some of the most recent formats might not be
        /// available so its best to check before using them.
        static func isSupported(type: AssetType) -> Bool {
            if let isAvailable = availability.value[type] {
                return isAvailable
            }
            let isAvailable = CGImageDestinationCreateWithData(
                NSMutableData() as CFMutableData, type.rawValue as CFString, 1, nil
            ) != nil
            availability.withLock { $0[type] = isAvailable }
            return isAvailable
        }

        func encode(_ image: PlatformImage) -> Data? {
            guard let source = image.cgImage,
                  let data = CFDataCreateMutable(nil, 0),
                  let destination = CGImageDestinationCreateWithData(data, type.rawValue as CFString, 1, nil) else {
                return nil
            }
            var options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: compressionRatio
            ]
            #if canImport(UIKit)
            options[kCGImagePropertyOrientation] = CGImagePropertyOrientation(image.imageOrientation).rawValue
            #endif
            CGImageDestinationAddImage(destination, source, options as CFDictionary)
            guard CGImageDestinationFinalize(destination) else {
                return nil
            }
            return data as Data
        }
    }
}
