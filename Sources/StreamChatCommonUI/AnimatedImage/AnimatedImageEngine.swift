//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

// The playback engine behind `StreamAnimatedImageView`. The view only holds it through this
// protocol, so tests can replace it.
@MainActor
protocol AnimatedImageEngine: AnyObject {
    // Called with each frame, in display order, only between `play()` and `stop()`.
    var onFrame: ((UIImage) -> Void)? { get set }

    // Checked on every tick. While it returns false, the engine neither advances nor decodes.
    var visibilityCheck: (() -> Bool)? { get set }

    // Parses `data` synchronously and returns false when it is not an animatable GIF, so the
    // caller can fall back to a static image. Discards the previous animation and never
    // delivers a frame itself. `targetPixelSize` is a decode size hint the engine may ignore.
    @discardableResult
    func load(data: Data, targetPixelSize: CGSize?) -> Bool

    // Starts or resumes looping playback. Does nothing when already playing or when nothing
    // is loaded. The first frame arrives asynchronously.
    func play()

    // Pauses playback and keeps the animation, so `play()` can resume it.
    func stop()

    // Stops playback and frees the loaded animation.
    func unload()

    var isPlaying: Bool { get }
}
