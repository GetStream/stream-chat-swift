//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the video duration to textual representation.
public protocol AudioRateFormatter {
    func format(_ rate: Float) -> String?
}

/// The default video duration formatter.
open class DefaultAudioRateFormatter: AudioRateFormatter {
    public var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter
    }()

    public init() {}

    open func format(_ rate: Float) -> String? {
        numberFormatter.string(from: rate as NSNumber)
    }
}
