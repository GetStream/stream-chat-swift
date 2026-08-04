//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// The playback engine behind ``StreamAnimatedImageView``.
///
/// The view owns the engine strongly and only ever holds it through this seam, so the
/// rendering strategy can be swapped without touching the view.
@MainActor
protocol AnimatedImageEngine: AnyObject {
    /// Called with each frame, in display order.
    ///
    /// Fires only between `play()` and `stop()`, never after `stop()` (or a new `load`) returns.
    var onFrame: ((UIImage) -> Void)? { get set }

    /// Parses `data` synchronously and reports whether it can be animated.
    ///
    /// Returns `false` when the data is not an animatable GIF (not a GIF, corrupt, or fewer
    /// than two frames), in which case the caller falls back to a static image. Implies
    /// `stop()` and discards any previously loaded animation. Never delivers a frame itself.
    ///
    /// - Parameter targetPixelSize: A decode size hint: maximum bounds, aspect ratio preserved,
    ///   never upscaled. Engines are free to ignore it.
    @discardableResult
    func load(data: Data, targetPixelSize: CGSize?) -> Bool

    /// Starts or resumes playback, looping forever.
    ///
    /// A no-op when already playing or when nothing is loaded. The first frame is delivered
    /// asynchronously.
    func play()

    /// Pauses playback, keeping the loaded animation so `play()` can resume it.
    ///
    /// The resume position is best-effort and engine specific.
    func stop()

    /// Whether playback is running, i.e. between a successful `play()` and `stop()`.
    var isPlaying: Bool { get }
}
