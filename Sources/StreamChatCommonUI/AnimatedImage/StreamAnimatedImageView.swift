//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import UIKit

/// An image view that renders animated GIF data.
///
/// Pass the raw bytes to ``setAnimatedImage(data:fallbackImage:)``. Playback runs while the
/// view is in a window and the app is in the foreground. It pauses while the view is hidden,
/// for example in a reuse pool, or scrolled off screen. ``stopAnimating()`` opts out until
/// ``startAnimating()`` or a new animation is set.
///
/// Assigning `image` directly does not stop playback: call ``clearAnimatedImage()`` first
/// when switching the view back to a static image.
///
/// `isAnimating` deliberately keeps its `UIImageView` meaning and stays `false` during GIF
/// playback: UIKit consults it when rendering `image`, and reporting `true` would make it
/// ignore the delivered frames. Use ``animatedImageData`` to check for a loaded animation.
@MainActor
open class StreamAnimatedImageView: UIImageView {
    /// The data of the currently loaded animation, or `nil` when the view shows a static image.
    public private(set) var animatedImageData: Data?

    var engine: AnimatedImageEngine = StreamAnimatedImageEngine()

    private var nonAnimatableData: Data?
    private var isPlaybackEnabled = false
    private var isApplicationInBackground = false
    private var isEngineConfigured = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Loads animated image data and starts playback.
    ///
    /// Setting data equal to ``animatedImageData`` does not reload or restart the animation,
    /// but re-enables playback, which makes repeated calls with the same content free.
    ///
    /// - Parameters:
    ///   - data: The encoded animation bytes.
    ///   - fallbackImage: The image shown until the first frame is rendered, and kept as the
    ///     static content when the data turns out not to be animatable. Defaults to the first
    ///     frame decoded from `data`.
    /// - Returns: Whether the data was loaded as an animation.
    @discardableResult
    open func setAnimatedImage(data: Data, fallbackImage: UIImage? = nil) -> Bool {
        if data == animatedImageData {
            isPlaybackEnabled = true
            playIfPossible()
            return true
        }
        if data == nonAnimatableData {
            return false
        }
        configureEngineIfNeeded()
        image = fallbackImage ?? UIImage(data: data)
        guard engine.load(data: data, targetPixelSize: nil) else {
            animatedImageData = nil
            nonAnimatableData = data
            isPlaybackEnabled = false
            return false
        }
        animatedImageData = data
        nonAnimatableData = nil
        isPlaybackEnabled = true
        playIfPossible()
        return true
    }

    /// Stops playback and discards the loaded animation, leaving `image` as it is.
    open func clearAnimatedImage() {
        engine.unload()
        animatedImageData = nil
        nonAnimatableData = nil
        isPlaybackEnabled = false
    }

    override open func startAnimating() {
        guard animatedImageData != nil else {
            super.startAnimating()
            return
        }
        isPlaybackEnabled = true
        playIfPossible()
    }

    override open func stopAnimating() {
        isPlaybackEnabled = false
        engine.stop()
        super.stopAnimating()
    }

    override open func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            engine.stop()
        } else {
            playIfPossible()
        }
    }

    // MARK: - Private

    private func configureEngineIfNeeded() {
        guard !isEngineConfigured else { return }
        isEngineConfigured = true
        engine.onFrame = { [weak self] frame in
            self?.image = frame
        }
        // Reuse pools and scroll views hide views without any lifecycle callback, so the engine
        // asks on every tick.
        engine.visibilityCheck = { [weak self] in
            self?.isVisibleOnScreen ?? false
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private var isVisibleOnScreen: Bool {
        guard let window else { return false }
        var view: UIView? = self
        while let current = view {
            if current.isHidden {
                return false
            }
            view = current.superview
        }
        return convert(bounds, to: window).intersects(window.bounds)
    }

    private func playIfPossible() {
        guard isPlaybackEnabled,
              !engine.isPlaying,
              animatedImageData != nil,
              window != nil,
              !isApplicationInBackground else { return }
        engine.play()
    }

    @objc private func handleApplicationDidEnterBackground() {
        isApplicationInBackground = true
        engine.stop()
    }

    @objc private func handleApplicationWillEnterForeground() {
        isApplicationInBackground = false
        playIfPossible()
    }
}
