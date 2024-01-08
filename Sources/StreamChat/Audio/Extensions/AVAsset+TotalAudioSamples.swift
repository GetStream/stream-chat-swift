//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAsset {
    /// The total number of samples in the audio track is calculated using the duration and the sample rate
    /// of the basic audio format description.
    func totalSamplesOfFirstAudioTrack() -> Int {
        guard
            let audioAssetTrack = tracks(withMediaType: .audio).first,
            let descriptions = audioAssetTrack.formatDescriptions as? [CMFormatDescription]
        else {
            return 0
        }

        return descriptions.reduce(0) { totalSamples, formatDescription in
            guard
                let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
            else {
                return totalSamples
            }

            let channelCount = Int(basicDescription.pointee.mChannelsPerFrame)
            let sampleRate = basicDescription.pointee.mSampleRate
            let duration = Double(duration.value)
            let timescale = Double(self.duration.timescale)
            let totalDuration = duration / timescale

            return Int(sampleRate * totalDuration) * channelCount
        }
    }
}
