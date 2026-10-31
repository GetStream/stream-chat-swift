//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import StreamChatCommonUI
import UIKit

/// A view that shows playback controls and timeline for the given player.
open class VideoPlaybackControlView: _View, ThemeProvider {
    /// The type describing the content of the view.
    public struct Content {
        /// The type describing the current video state.
        public enum VideoState {
            case playing
            case paused
            case loading
        }

        /// A video duration in seconds.
        public var videoDuration: TimeInterval
        /// A video playback state.
        public var videoState: VideoState
        /// A video playback progress in [0...1] range
        public var playingProgress: Double

        /// A current location in video.
        public var currentTime: TimeInterval {
            playingProgress * videoDuration
        }

        public init(
            videoDuration: TimeInterval,
            videoState: VideoState,
            playingProgress: Double
        ) {
            self.videoDuration = videoDuration
            self.videoState = videoState
            self.playingProgress = playingProgress
        }

        public static var initial: Self {
            .init(
                videoDuration: 0,
                videoState: .loading,
                playingProgress: 0
            )
        }
    }

    private var playerTimeChangesObserver: Any?
    private var playerStatusObserver: NSKeyValueObservation?
    private var playerItemObserver: NSKeyValueObservation?
    private var itemDurationObserver: NSKeyValueObservation?
    private var itemStatusObserver: NSKeyValueObservation?
    private weak var observedItem: AVPlayerItem?
    // Kept independent of `Content.VideoState` so existing exhaustive switches stay compatible.
    private var hasPlaybackFailed = false

    /// Whether the timeline is being scrubbed, so periodic time updates do not move it back.
    open private(set) var isScrubbing = false

    /// Whether the player was playing when the user started scrubbing the timeline.
    open private(set) var wasPlayingBeforeScrubbing = false

    /// A content displayed by the view.
    open var content: Content = .initial {
        didSet { updateContentIfNeeded() }
    }

    /// A player the view listens to.
    open weak var player: AVPlayer? {
        didSet {
            guard oldValue != player else { return }

            unsubscribeFromPlayerNotifications(oldValue)
            clearPlaybackFailure()
            content = .initial
            subscribeToPlayerNotifications()

            if player != nil {
                player?.seek(to: .zero)
                playPlayer()
            } else {
                deactivatePlaybackAudioSession()
            }
        }
    }

    /// A loading indicator that is visible when video is loading.
    open private(set) lazy var loadingIndicator: ChatLoadingIndicator = components
        .loadingIndicator.init()
        .withoutAutoresizingMaskConstraints

    /// A playback control button.
    open private(set) lazy var playPauseButton: UIButton = UIButton()
        .withoutAutoresizingMaskConstraints

    /// A label displaying the current time position.
    open private(set) lazy var timestampLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport

    /// A label displaying the overall video duration.
    open private(set) lazy var durationLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport

    /// A slider used to show a timeline.
    open private(set) lazy var timeSlider: UISlider = UISlider()
        .withoutAutoresizingMaskConstraints

    /// A label shown when the current video cannot be played.
    open private(set) lazy var errorLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withAdjustingFontForContentSizeCategory
        .withBidirectionalLanguagesSupport
        .withNumberOfLines(0)
        .withAccessibilityIdentifier(identifier: "errorLabel")

    /// A container for playback button and time labels.
    open private(set) lazy var rootContainer: ContainerStackView = ContainerStackView(axis: .vertical)
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "rootContainer")

    /// A formatter to convert video duration to textual representation.
    open lazy var videoDurationFormatter: VideoDurationFormatter = appearance.formatters.videoDuration

    override open func setUp() {
        super.setUp()

        timeSlider.minimumValue = 0
        timeSlider.maximumValue = 1
        timeSlider.addTarget(self, action: #selector(timeSliderEditingDidBegin), for: .touchDown)
        timeSlider.addTarget(self, action: #selector(timeSliderDidChange), for: .valueChanged)
        timeSlider.addTarget(
            self,
            action: #selector(timeSliderEditingDidEnd),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )

        timestampLabel.font = appearance.fonts.footnoteBold
        durationLabel.font = appearance.fonts.footnoteBold

        playPauseButton.addTarget(self, action: #selector(handleTapOnPlayPauseButton), for: .touchUpInside)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        let bottomContainer = UIView().withoutAutoresizingMaskConstraints

        bottomContainer.addSubview(timestampLabel)
        timestampLabel.pin(anchors: [.leading, .top], to: bottomContainer)

        bottomContainer.addSubview(playPauseButton)
        playPauseButton.pin(anchors: [.centerX, .top, .bottom], to: bottomContainer)

        bottomContainer.addSubview(durationLabel)
        durationLabel.pin(anchors: [.trailing, .top], to: bottomContainer)

        addSubview(rootContainer)
        rootContainer.pin(to: self)
        rootContainer.addArrangedSubview(timeSlider, respectsLayoutMargins: true)
        rootContainer.addArrangedSubview(bottomContainer, respectsLayoutMargins: true)

        addSubview(loadingIndicator)
        loadingIndicator.pin(anchors: [.centerX, .centerY], to: playPauseButton)

        addSubview(errorLabel)
        errorLabel.pin(anchors: [.leading, .trailing], to: layoutMarginsGuide)
        errorLabel.pin(anchors: [.centerY], to: playPauseButton)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        playPauseButton.setTitleColor(.black, for: .normal)
        timestampLabel.text = videoDurationFormatter.format(0)
        durationLabel.text = videoDurationFormatter.format(0)
        timeSlider.accessibilityLabel = L10n.Gallery.Playback.timeline
        timeSlider.accessibilityUserInputLabels = [L10n.Gallery.Playback.timeline]
        playPauseButton.accessibilityLabel = L10n.Gallery.Playback.play
        timestampLabel.isAccessibilityElement = false
        durationLabel.isAccessibilityElement = false
        errorLabel.font = appearance.fonts.footnote
        errorLabel.textColor = appearance.colorPalette.accentError
        errorLabel.textAlignment = .center
        errorLabel.text = L10n.Gallery.Playback.error
        errorLabel.accessibilityLabel = L10n.Gallery.Playback.error
        errorLabel.accessibilityTraits = .staticText
        errorLabel.isHidden = true
        errorLabel.isAccessibilityElement = false
    }

    override open func updateContent() {
        super.updateContent()

        timeSlider.value = .init(content.playingProgress)
        timestampLabel.text = videoDurationFormatter.format(content.currentTime)
        durationLabel.text = videoDurationFormatter.format(content.videoDuration)
        timeSlider.accessibilityValue = videoDurationFormatter.format(content.currentTime)

        if hasPlaybackFailed {
            presentFailureContent()
            return
        }

        errorLabel.isHidden = true
        errorLabel.isAccessibilityElement = false
        timeSlider.isHidden = false
        timeSlider.isEnabled = true
        timestampLabel.isHidden = false
        durationLabel.isHidden = false
        playPauseButton.isEnabled = true

        switch content.videoState {
        case .playing:
            playPauseButton.isHidden = false
            playPauseButton.setImage(appearance.images.pause, for: .normal)
            playPauseButton.accessibilityLabel = L10n.Gallery.Playback.pause
            playPauseButton.accessibilityUserInputLabels = [L10n.Gallery.Playback.pause]
        case .paused:
            playPauseButton.isHidden = false
            playPauseButton.setImage(appearance.images.play, for: .normal)
            playPauseButton.accessibilityLabel = L10n.Gallery.Playback.play
            playPauseButton.accessibilityUserInputLabels = [L10n.Gallery.Playback.play]
        case .loading:
            playPauseButton.isHidden = true
            playPauseButton.accessibilityLabel = L10n.Gallery.Playback.play
            playPauseButton.accessibilityUserInputLabels = [L10n.Gallery.Playback.play]
        }

        let showLoader = playPauseButton.isHidden
        if loadingIndicator.isVisible != showLoader {
            loadingIndicator.isVisible = showLoader
        }
    }

    func setPlaybackFailure(_ error: Error?) {
        if let error {
            presentPlaybackFailure(error)
        } else {
            clearPlaybackFailure()
        }
    }

    /// Called when the user starts dragging the timeline.
    @objc open func timeSliderEditingDidBegin(_ sender: UISlider) {
        guard !hasPlaybackFailed else { return }
        isScrubbing = true
        wasPlayingBeforeScrubbing = player?.timeControlStatus == .playing
        player?.pause()
    }

    /// Is invoked when time slider changes the value.
    @objc open func timeSliderDidChange(_ sender: UISlider, event: UIEvent) {
        seekPlayer(toProgress: sender.value)
    }

    /// Called when the user stops dragging the timeline.
    @objc open func timeSliderEditingDidEnd(_ sender: UISlider) {
        seekPlayer(toProgress: sender.value)
        isScrubbing = false
        if wasPlayingBeforeScrubbing {
            playPlayer()
        }
        wasPlayingBeforeScrubbing = false
    }

    /// Seeks the player to the given timeline progress, a value between 0 and 1.
    open func seekPlayer(toProgress progress: Float) {
        guard !hasPlaybackFailed else { return }
        let progress = min(max(progress, 0), 1)
        let duration: TimeInterval
        if content.videoDuration.isFinite, content.videoDuration > 0 {
            duration = content.videoDuration
        } else if let itemDuration = player?.currentItem?.duration, itemDuration.isNumeric {
            duration = itemDuration.seconds
        } else {
            content.playingProgress = Double(progress)
            return
        }
        let time = CMTime(seconds: duration * Double(progress), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        content.playingProgress = Double(progress)
    }

    /// Is invoked when current track reached the end.
    @objc open func handleItemDidPlayToEndTime(_ notification: NSNotification) {
        guard !hasPlaybackFailed else { return }
        guard notification.object as AnyObject? === player?.currentItem else { return }
        player?.seek(to: .zero)
    }

    /// Is invoked when the current item fails to play to the end.
    @objc open func handleItemFailedToPlayToEndTime(_ notification: NSNotification) {
        StreamConcurrency.onMain { [weak self] in
            guard let self else { return }
            guard notification.object as AnyObject? === self.player?.currentItem else { return }
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            self.presentPlaybackFailure(error)
        }
    }

    /// Starts playback so video audio is heard even when the ringer switch is off.
    open func playPlayer() {
        guard !hasPlaybackFailed else { return }
        activatePlaybackAudioSession()
        player?.play()
    }

    /// Uses the playback category so the hardware ringer switch does not mute gallery video.
    open func activatePlaybackAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            log.error("Failed to configure the audio session for gallery playback: \(error)")
        }
    }

    /// Releases the playback session so the ringer switch and other audio can take over again.
    open func deactivatePlaybackAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            log.error("Failed to deactivate the audio session after gallery playback: \(error)")
        }
    }

    /// Is invoked when playback button is touched up inide.
    @objc open func handleTapOnPlayPauseButton() {
        guard !hasPlaybackFailed else { return }
        switch player?.timeControlStatus {
        case .paused:
            playPlayer()
        case .playing:
            player?.pause()
        default:
            break
        }
    }

    /// Unsubscribes from all notifications.
    /// Is invoked with old player when new player is set or when current view is deallocated.
    open func unsubscribeFromPlayerNotifications(_ player: AVPlayer?) {
        playerTimeChangesObserver.map { player?.removeTimeObserver($0) }
        playerTimeChangesObserver = nil

        playerStatusObserver?.invalidate()
        playerStatusObserver = nil

        playerItemObserver?.invalidate()
        playerItemObserver = nil

        unobservePlayerItem()
    }

    /// Unsubscribes to current player notifications.
    /// Is invoked when new player is set.
    open func subscribeToPlayerNotifications() {
        guard let player = player else { return }

        let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        playerTimeChangesObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            StreamConcurrency.onMain {
                guard let self, !self.hasPlaybackFailed, !self.isScrubbing else { return }
                guard player === self.player, let currentItem = self.player?.currentItem else { return }

                if time.isNumeric && currentItem.duration.isNumeric {
                    self.content.playingProgress = time.seconds / currentItem.duration.seconds
                } else {
                    self.content.playingProgress = 0
                }
            }
        }

        playerStatusObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            guard let self = self else { return }
            StreamConcurrency.onMain {
                guard player === self.player, !self.hasPlaybackFailed else { return }
                switch player.timeControlStatus {
                case .playing:
                    self.content.videoState = .playing
                case .paused:
                    self.content.videoState = .paused
                default:
                    self.content.videoState = .loading
                }
            }
        }

        playerItemObserver = player.observe(\.currentItem, options: [.new]) { [weak self] player, _ in
            guard let self = self else { return }
            StreamConcurrency.onMain {
                guard player === self.player else { return }
                self.handleCurrentItemChange(player.currentItem)
            }
        }
        handleCurrentItemChange(player.currentItem)
    }

    // This is a workaround to overcome the Swift 6 warning
    private var _currentPlayer: AVPlayer? { player }

    deinit {
        NotificationCenter.default.removeObserver(self)
        StreamConcurrency.onMain {
            unsubscribeFromPlayerNotifications(_currentPlayer)
        }
    }

    private func presentFailureContent() {
        errorLabel.text = L10n.Gallery.Playback.error
        errorLabel.accessibilityLabel = L10n.Gallery.Playback.error
        errorLabel.isHidden = false
        errorLabel.isAccessibilityElement = true
        playPauseButton.isHidden = true
        playPauseButton.isEnabled = false
        timeSlider.isHidden = true
        timeSlider.isEnabled = false
        timestampLabel.isHidden = true
        durationLabel.isHidden = true
        if loadingIndicator.isVisible {
            loadingIndicator.isVisible = false
        }
    }

    private func presentPlaybackFailure(_ error: Error?) {
        if let error {
            log.error("Gallery video playback failed: \(error)")
        }
        hasPlaybackFailed = true
        isScrubbing = false
        wasPlayingBeforeScrubbing = false
        player?.pause()
        updateContentIfNeeded()
    }

    private func clearPlaybackFailure() {
        guard hasPlaybackFailed else { return }
        hasPlaybackFailed = false
        updateContentIfNeeded()
    }

    private func handleCurrentItemChange(_ item: AVPlayerItem?) {
        let itemChanged = item !== observedItem
        unobservePlayerItem()
        clearPlaybackFailure()
        content.videoDuration = 0
        content.playingProgress = 0
        observePlayerItem(item)

        if item == nil {
            content.videoState = .loading
        } else if itemChanged, item?.status != .failed, !hasPlaybackFailed {
            playPlayer()
        }
    }

    private func observePlayerItem(_ item: AVPlayerItem?) {
        guard let item else { return }

        observedItem = item

        itemDurationObserver = item.observe(\.duration, options: [.new, .initial]) { [weak self] item, _ in
            StreamConcurrency.onMain { [weak self] in
                guard let self, !self.hasPlaybackFailed, item === self.player?.currentItem else { return }
                self.content.videoDuration = item.duration.isNumeric ? item.duration.seconds : 0
            }
        }

        itemStatusObserver = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            StreamConcurrency.onMain { [weak self] in
                guard let self, item === self.player?.currentItem else { return }
                if item.status == .failed {
                    self.presentPlaybackFailure(item.error)
                }
            }
        }
        if item.status == .failed {
            presentPlaybackFailure(item.error)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleItemDidPlayToEndTime),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleItemFailedToPlayToEndTime),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item
        )
    }

    private func unobservePlayerItem() {
        // KVO keeps `observedItem` alive; remove its notifications before invalidating.
        if let observedItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: observedItem)
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: observedItem)
        }

        itemDurationObserver?.invalidate()
        itemDurationObserver = nil

        itemStatusObserver?.invalidate()
        itemStatusObserver = nil

        observedItem = nil
    }
}
