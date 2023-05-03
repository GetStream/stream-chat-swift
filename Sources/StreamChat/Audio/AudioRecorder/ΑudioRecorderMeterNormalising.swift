//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines an object that will be used by an AudioRecorder to normalise the values of its averagePower
protocol ΑudioRecorderMeterNormalising {
    func normalise(_ value: Float) -> Float
}

struct StreamΑudioRecorderMeterNormaliser: ΑudioRecorderMeterNormalising {
    /// Any audio below the minimumLevelThreshold is considered silence.
    /// Note: Default value: -50
    var minimumLevelThreshold: Float = -50

    init() {}

    /// Transforms the given value - that represents the averagePower of a an AVAudioRecorder - to a
    /// percentage.
    /// - Parameter value: the averagePower of the AVAudioRecorder in `dBFS`. The ranges between
    /// `-160dBFS` indicating minimum power, to `0 dBFS`, indicating maximum power.
    /// - Returns: the percentage representation of the provided value
    func normalise(
        _ value: Float
    ) -> Float {
        guard value >= minimumLevelThreshold else { return 0 }
        let percentage = (minimumLevelThreshold - value) / minimumLevelThreshold
        return percentage
    }
}
