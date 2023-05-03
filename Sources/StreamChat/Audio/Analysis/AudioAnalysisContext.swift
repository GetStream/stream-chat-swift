//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// An object describing the context of an AudioTrack analysis process
struct AudioAnalysisContext {
    /// The URL location of the AudioTrack under analysis
    let audioURL: URL

    /// The number of samples contained in the AudioTrack
    let totalSamples: Int

    /// The asset pointing to the AudioTrack
    let asset: AVAsset

    /// The first audio track available in the asset (if any)
    let assetTrack: AVAssetTrack?

    init(
        audioURL: URL,
        totalSamples: Int,
        asset: AVAsset,
        assetTrack: AVAssetTrack?
    ) {
        self.audioURL = audioURL
        self.totalSamples = totalSamples
        self.asset = asset
        self.assetTrack = assetTrack
    }

    init(
        from loadedAsset: AVAsset,
        audioURL: URL
    ) throws {
        guard
            let assetTrack = loadedAsset.tracks(withMediaType: .audio).first,
            let formatDescriptions = assetTrack.formatDescriptions as? [CMAudioFormatDescription],
            let audioFormatDesc = formatDescriptions.first,
            let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc)
        else {
            throw AudioAnalysisEngineError.failedToLoadFormatDescriptions()
        }

        // The total number of samples in the audio track is calculated
        // using the duration and the sample rate of the basic audio
        // format description.
        let totalSamples = Int(
            (basicDescription.pointee.mSampleRate) * Float64(loadedAsset.duration.value) / Float64(loadedAsset.duration.timescale)
        )

        self.init(
            audioURL: audioURL,
            totalSamples: totalSamples,
            asset: loadedAsset,
            assetTrack: assetTrack
        )
    }
}
