//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the uploading progress to textual representation.
public protocol UploadingProgressFormatter {
    func format(_ progress: Double) -> String?
}

/// The default uploading progress formatter.
open class DefaultUploadingProgressFormatter: UploadingProgressFormatter {
    public var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()

    public init() {}

    open func format(_ progress: Double) -> String? {
        numberFormatter.string(from: .init(value: progress))
    }
}
