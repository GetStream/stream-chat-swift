//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Provides a custom `AVPlayer` from a `MediaLoaderVideoAsset`.
///
/// Conform to this protocol to provide a custom player configuration.
/// The video asset already contains CDN headers baked into its `AVURLAsset`,
/// resolved through ``MediaLoader/videoAsset(at:options:completion:)``.
public protocol AVPlayerProvider {
    /// Creates and returns an `AVPlayer` from the given video asset.
    /// - Parameters:
    ///   - videoAsset: A video asset already resolved through the `MediaLoader`.
    ///   - completion: A completion that is called when the player is ready or an error occurred.
    func player(
        from videoAsset: MediaLoaderVideoAsset,
        completion: @escaping (Result<AVPlayer, Error>) -> Void
    )
}

/// The default implementation that creates an `AVPlayer` from a `MediaLoaderVideoAsset`.
public final class DefaultAVPlayerProvider: AVPlayerProvider {
    public init() {}

    public func player(
        from videoAsset: MediaLoaderVideoAsset,
        completion: @escaping (Result<AVPlayer, Error>) -> Void
    ) {
        let playerItem = AVPlayerItem(asset: videoAsset.asset)
        completion(.success(AVPlayer(playerItem: playerItem)))
    }
}
