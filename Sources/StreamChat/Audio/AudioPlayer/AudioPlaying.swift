//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// A protocol describing an object that can be manage the playback of an audio file or stream.
public protocol AudioPlaying: AnyObject {
    init()

    /// Subscribes the provided object on AudioPlayer's updates
    func subscribe(_ subscriber: AudioPlayingDelegate)

    /// Instructs the player to load the asset from the provided URL and prepare it for streaming. If the
    /// player's current item has a URL that matches the provided one, then we will try to play or restart
    /// the playback while updating the new delegate.
    /// - Parameters:
    ///   - url: The URL where the asset will be streamed from
    ///   - delegate: The delegate that will be informed for changes on the asset's playback.
    func loadAsset(from url: URL)

    /// Begin the loaded asset's playback. If no asset has been loaded, the action has no effect.
    func play()

    /// Pauses the loaded asset's playback. If non has been loaded or the playback hasn't started yet
    /// the action has no effect.
    func pause()

    /// Stop the loaded asset's playback. If non has been loaded or the playback hasn't started yet
    /// the action has no effect.
    func stop()

    /// Updates the loaded asset's playback rate to the provided one.
    /// - Parameter newRate: The new rate which we want the player to use for playback
    func updateRate(_ newRate: AudioPlaybackRate)

    /// Performs a seek in the loaded asset's timeline at the provided time.
    /// - Parameter time: The time to seek at
    func seek(to time: TimeInterval)
}

/// An implementation of ``AudioPlaying`` that can be used to stream audio files from a URL
open class StreamAudioPlayer: AudioPlaying, AppStateObserverDelegate {
    // MARK: - Properties
    
    /// Provides thread-safe access to context storage
    private lazy var contextValueAccessor: AudioPlaybackContextAccessor = .init(.notLoaded)
    /// Describes the player's current playback state. The access to this property is thread-safe
    private(set) var context: AudioPlaybackContext {
        get { contextValueAccessor.value }
        set {
            contextValueAccessor.value = newValue
            notifyDelegates()
        }
    }

    /// The delegate which should get informed when the player's context gets updated
    private lazy var multicastDelegate: MulticastDelegate<AudioPlayingDelegate> = .init()

    /// The player that will be used for the playback of the audio files
    fileprivate let player: AVPlayer

    private var audioSessionConfigurator: AudioSessionConfiguring

    /// The assetPropertyLoader is being used during the loading of an asset with non-nil URL, to provide
    /// async information about the asset's properties. Currently, we are only loading the `duration`
    /// property.
    private let assetPropertyLoader: AssetPropertyLoading

    /// An observer that acts as a mediator between the AVPlayer and StreamAudioPlayer for playback
    /// updates.
    private let playerObserver: AudioPlayerObserving

    private let appStateObserver: AppStateObserving

    private var shouldPlayWhenComeToForeground = false

    // MARK: - Lifecycle

    public required convenience init() {
        self.init(
            assetPropertyLoader: StreamAssetPropertyLoader(),
            playerObserver: StreamPlayerObserver(),
            player: .init(),
            audioSessionConfigurator: StreamAudioSessionConfigurator(),
            appStateObserver: StreamAppStateObserver()
        )
    }

    init(
        assetPropertyLoader: AssetPropertyLoading,
        playerObserver: AudioPlayerObserving,
        player: AVPlayer,
        audioSessionConfigurator: AudioSessionConfiguring,
        appStateObserver: AppStateObserving
    ) {
        self.assetPropertyLoader = assetPropertyLoader
        self.playerObserver = playerObserver
        self.player = player
        self.audioSessionConfigurator = audioSessionConfigurator
        self.appStateObserver = appStateObserver

        setUp()
    }

    /// Provides a way to customise of the underline audioSessionConfiguration, in order to allow extension
    /// on the logic that handles the `AVAudioSession.shared`.
    /// - Parameters:
    ///     - audioSessionConfiguration: The new instance of the audioSessionConfigurator that will
    ///     be used whenever the player needs to interact with the `AVAudioSession.shared`.
    public func configure(_ audioSessionConfigurator: AudioSessionConfiguring) {
        self.audioSessionConfigurator = audioSessionConfigurator
    }

    // MARK: - AudioPlaying

    open func subscribe(_ subscriber: AudioPlayingDelegate) {
        multicastDelegate.add(additionalDelegate: subscriber)
        subscriber.audioPlayer(self, didUpdateContext: context)
    }

    open func loadAsset(from url: URL) {
        /// We are going to check if the URL requested to load, represents the currentItem that we
        /// have already loaded (if any). In this case, we will try either to resume the existing playback
        /// or restart it, if possible.
        if let currentItem = player.currentItem?.asset as? AVURLAsset,
           url == currentItem.url,
           context.assetLocation == url {
            /// If the currentItem is paused, we want to continue the playback
            /// Otherwise, no action is required
            if context.state == .paused {
                play()
            } else if context.state == .stopped {
                /// If the currentItem has stopped, we want to restart the playback. We are replacing
                /// the currentItem with the same one to trigger the player's observers on the updated
                /// currentItem.
                player.replaceCurrentItem(with: .init(asset: currentItem))
                play()
            }

            /// This case may be triggered if we call ``loadAsset`` on a player that is currently
            /// playing the URL we provided. In this case we will Inform the delegate about the
            /// current state.
            notifyDelegates()

            return
        }

        /// We call stop to update the currently set delegate that the playback has been stopped
        /// and then we remove the current item from the player's queue.
        stop()
        player.replaceCurrentItem(with: nil)

        updateContext {
            $0.state = .loading
            $0.assetLocation = url
        }
        let asset = AVURLAsset(url: url)

        assetPropertyLoader.loadProperties(
            [.init(\.duration)],
            of: asset
        ) { [weak self] in self?.handleDurationLoading($0) }
    }

    open func play() {
        do {
            try audioSessionConfigurator.activatePlaybackSession()
            player.play()
        } catch {
            log.error(error)
            stop()
        }
    }

    open func pause() {
        player.pause()
    }

    open func stop() {
        do {
            /// As the AVPlayer doesn't provide an API to actually stop the playback, we are simulating it
            /// by calling pause
            pause()

            try audioSessionConfigurator.deactivatePlaybackSession()

            updateContext { value in
                value = .init(
                    assetLocation: value.assetLocation,
                    duration: value.duration,
                    currentTime: 0,
                    state: .stopped,
                    rate: .zero,
                    isSeeking: false
                )
            }
        } catch {
            log.error(error)
        }
    }

    open func updateRate(_ newRate: AudioPlaybackRate) {
        player.rate = newRate.rawValue
    }

    open func seek(to time: TimeInterval) {
        pause()
        updateContext { value in
            value.state = .paused
            value.currentTime = time
            value.isSeeking = true
        }
        executeSeek(to: time)
    }

    // MARK: - AppStateObserverDelegate

    func applicationDidMoveToBackground() {
        guard context.state == .playing else { return }
        shouldPlayWhenComeToForeground = true
        pause()
    }

    func applicationDidMoveToForeground() {
        guard shouldPlayWhenComeToForeground else { return }
        shouldPlayWhenComeToForeground = false
        play()
    }

    // MARK: - Helpers

    func playbackWillStop(_ playerItem: AVPlayerItem) {
        guard
            let playerItemURL = (playerItem.asset as? AVURLAsset)?.url,
            let currentItemURL = (player.currentItem?.asset as? AVURLAsset)?.url,
            playerItemURL == currentItemURL
        else {
            return
        }
        updateContext { value in
            value.state = .stopped
            value.currentTime = 0
            value.rate = .zero
            value.isSeeking = false
        }
        notifyDelegates()
    }

    // MARK: - Private Helpers

    private func setUp() {
        let player = self.player
        let interval = CMTime(
            seconds: 0.1,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )

        playerObserver.addPeriodicTimeObserver(
            player,
            forInterval: interval,
            queue: nil
        ) { [weak self] in
            guard let self = self, self.context.isSeeking == false else {
                return
            }

            self.updateContext { value in
                let currentTime = player.currentTime().seconds
                value.currentTime = currentTime.isFinite && !currentTime.isNaN
                    ? TimeInterval(currentTime)
                    : .zero

                value.isSeeking = false

                value.rate = .init(rawValue: player.rate)
            }
        }

        playerObserver.addTimeControlStatusObserver(
            player
        ) { [weak self] newValue in
            guard let self = self, let newValue = newValue else {
                return
            }

            let currentPlaybackState = self.context.state

            self.updateContext { value in
                switch (newValue, currentPlaybackState) {
                case (.playing, .playing), (.paused, .paused):
                    break
                case (.paused, .playing), (.paused, .loading):
                    value.state = .paused
                    value.rate = .zero
                case (.playing, .paused), (.playing, .stopped), (.playing, .loading):
                    value.state = .playing
                default:
                    log.debug("\(type(of: self)): No action for transition \(currentPlaybackState) -> \(newValue)", subsystems: .audioPlayback)
                }
            }
        }

        playerObserver.addStoppedPlaybackObserver(
            queue: nil
        ) { [weak self] in self?.playbackWillStop($0) }

        appStateObserver.subscribe(self)
    }

    private func notifyDelegates() {
        multicastDelegate.invoke { $0.audioPlayer(self, didUpdateContext: context) }
    }

    /// Provides thread-safe updates for the player's context and makes sure to forward any updates
    /// to the the delegate
    private func updateContext(
        _ newContextProvider: (inout AudioPlaybackContext) -> Void
    ) {
        var newContext = context
        newContextProvider(&newContext)
        context = newContext
    }

    /// It's used by the assetPropertyLoader to handle the completion (successful or failed) of duration's
    /// asynchronous loading.
    private func handleDurationLoading(
        _ result: Result<AVURLAsset, AssetPropertyLoadingCompositeError>
    ) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handleDurationLoading(result)
            }
            return
        }

        switch result {
        /// If the assetPropertyLoaded managed to successfully load the asset's duration information
        /// we update the context with the new information.
        case let .success(asset):
            player.replaceCurrentItem(with: .init(asset: asset))
            updateContext { value in
                value.duration = asset.duration.seconds
                value.currentTime = 0
                value.rate = .zero
                value.isSeeking = false
            }

            play()

        /// If the assetPropertyLoader failed to load the asset's duration information we update the
        /// context with the notLoaded state in order to inform the delegate and we log a debug error message
        case let .failure(error):
            updateContext { value in
                value.duration = 0
                value.currentTime = 0
                value.rate = .zero
                value.state = .notLoaded
                value.isSeeking = false
            }
            log.error(error.localizedDescription, subsystems: .audioPlayback)
        }
    }

    /// It executes a seek request at the specified time on the player in order to progress the playback.
    private func executeSeek(to time: TimeInterval) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.executeSeek(to: time)
            }
            return
        }

        guard context.isSeeking, let currentItem = player.currentItem else {
            return
        }

        let currentTimescale = currentItem.currentTime().timescale
        player.seek(
            to: CMTimeMakeWithSeconds(
                time,
                preferredTimescale: currentTimescale
            ),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] finished in
            guard finished else {
                return
            }
            self?.updateContext { value in value.isSeeking = false }
        }
    }
}
