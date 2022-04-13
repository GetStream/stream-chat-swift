//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
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
    
    /// A content displayed by the view.
    open var content: Content = .initial {
        didSet { updateContentIfNeeded() }
    }

    /// A player the view listens to.
    open weak var player: AVPlayer? {
        didSet {
            guard oldValue != player else { return }
            
            unsubscribeFromPlayerNotifications(oldValue)
            content = .initial
            subscribeToPlayerNotifications()
            
            player?.seek(to: .zero)
            player?.play()
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
        timeSlider.addTarget(self, action: #selector(timeSliderDidChange), for: .valueChanged)
        
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
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        playPauseButton.setTitleColor(.black, for: .normal)
        timestampLabel.text = videoDurationFormatter.format(0)
        durationLabel.text = videoDurationFormatter.format(0)
    }
    
    override open func updateContent() {
        super.updateContent()
        
        timeSlider.value = .init(content.playingProgress)
        timestampLabel.text = videoDurationFormatter.format(content.currentTime)
        durationLabel.text = videoDurationFormatter.format(content.videoDuration)
                
        switch content.videoState {
        case .playing:
            playPauseButton.isHidden = false
            playPauseButton.setImage(appearance.images.pause, for: .normal)
        case .paused:
            playPauseButton.isHidden = false
            playPauseButton.setImage(appearance.images.play, for: .normal)
        case .loading:
            playPauseButton.isHidden = true
        }
        
        let showLoader = playPauseButton.isHidden
        if loadingIndicator.isVisible != showLoader {
            loadingIndicator.isVisible = showLoader
        }
    }
    
    /// Is invoked when time slider changes the value.
    @objc open func timeSliderDidChange(_ sender: UISlider, event: UIEvent) {
        switch event.allTouches?.first?.phase {
        case .began:
            player?.pause()
        case .moved:
            let duration = player?.currentItem?.duration.seconds ?? 0
            let time = CMTime(seconds: duration * .init(sender.value), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        case .ended, .cancelled:
            player?.play()
        default:
            break
        }
    }
    
    /// Is invoked when current track reached the end.
    @objc open func handleItemDidPlayToEndTime(_ notification: NSNotification) {
        player?.seek(to: .zero)
    }
    
    /// Is invoked when playback button is touched up inide.
    @objc open func handleTapOnPlayPauseButton() {
        switch player?.timeControlStatus {
        case .paused:
            player?.play()
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

        itemDurationObserver?.invalidate()
        itemDurationObserver = nil
    }
    
    /// Unsubscribes to current player notifications.
    /// Is invoked when new player is set.
    open func subscribeToPlayerNotifications() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.05, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        playerTimeChangesObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let currentItem = self?.player?.currentItem else { return }
            
            if time.isNumeric && currentItem.duration.isNumeric {
                self?.content.playingProgress = time.seconds / currentItem.duration.seconds
            } else {
                self?.content.playingProgress = 0
            }
        }
        
        playerStatusObserver = player.observe(\.timeControlStatus, options: [.new, .initial]) { [weak self] player, _ in
            guard let self = self else { return }

            switch player.timeControlStatus {
            case .playing:
                self.content.videoState = .playing
            case .paused:
                self.content.videoState = .paused
            default:
                self.content.videoState = .loading
            }
        }
        
        playerItemObserver = player.observe(\.currentItem, options: [.new, .initial]) { [weak self] player, _ in
            guard let self = self else { return }
            
            self.content.videoDuration = 0
            self.itemDurationObserver = player.currentItem?.observe(\.duration, options: [.new, .initial]) { [weak self] item, _ in
                self?.content.videoDuration = item.duration.isNumeric ? item.duration.seconds : 0
            }
            
            NotificationCenter.default.removeObserver(self)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleItemDidPlayToEndTime),
                name: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem
            )
        }
    }
    
    deinit {
        unsubscribeFromPlayerNotifications(player)
    }
}
