// The MIT License (MIT)
//
// Copyright (c) 2015-2024 Alexander Grebenyuk (github.com/kean).

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
        private let closure: @Sendable (PlatformImage) -> PlatformImage?

        init(id: String, _ closure: @Sendable @escaping (PlatformImage) -> PlatformImage?) {
            self.identifier = id
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
