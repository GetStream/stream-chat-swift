//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the audio playback rate to textual representation.
public protocol AudioPlaybackRateFormatter {
    func format(_ rate: Float) -> String?
}

/// The default audio playback rate formatter.
open class DefaultAudioPlaybackRateFormatter: AudioPlaybackRateFormatter {
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
