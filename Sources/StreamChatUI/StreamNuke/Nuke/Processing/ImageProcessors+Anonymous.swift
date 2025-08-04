//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

#if !os(macOS)
import UIKit
#else
import AppKit
#endif

extension ImageProcessors {
    /// Processed an image using a specified closure.
    struct Anonymous: ImageProcessing, CustomStringConvertible {
        let identifier: String
        private let closure: @Sendable(PlatformImage) -> PlatformImage?

        init(id: String, _ closure: @Sendable @escaping (PlatformImage) -> PlatformImage?) {
            identifier = id
            self.closure = closure
        }

        func process(_ image: PlatformImage) -> PlatformImage? {
            closure(image)
        }

        var description: String {
            "AnonymousProcessor(identifier: \(identifier)"
        }
    }
}
