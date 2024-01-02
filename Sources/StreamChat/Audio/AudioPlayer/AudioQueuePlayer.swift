//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation

/// Describes an object that will be asked to provided the URL of the next AudioTrack to play whenever
/// the current one's playback has been completed.
public protocol AudioQueuePlayerDatasource: AnyObject {
    /// If there is one, provide the URL location of the next AudioTrack to play once the current's playback
    /// has been completed.
    /// - Parameters:
    ///   - audioPlayer: The audioPlayer that is currently playing.
    ///   - currentAssetURL: The current's AudioTrack (if any) URL location.
    /// - Returns: The URL location of the next AudioTrack
    func audioQueuePlayerNextAssetURL(
        _ audioPlayer: AudioPlaying,
        currentAssetURL: URL?
    ) -> URL?
}

open class StreamAudioQueuePlayer: StreamAudioPlayer {
    open weak var dataSource: AudioQueuePlayerDatasource?

    override open func playbackWillStop(_ playerItem: AVPlayerItem) {
        if let nextAssetURL = dataSource?.audioQueuePlayerNextAssetURL(self, currentAssetURL: context.assetLocation) {
            loadAsset(from: nextAssetURL)
        } else {
            stop()
        }
    }
}
