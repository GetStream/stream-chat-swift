//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    ) {
        self.init(
            audioURL: audioURL,
            totalSamples: loadedAsset.totalSamplesOfFirstAudioTrack(),
            asset: loadedAsset,
            assetTrack: loadedAsset.tracks(withMediaType: .audio).first
        )
    }
}
