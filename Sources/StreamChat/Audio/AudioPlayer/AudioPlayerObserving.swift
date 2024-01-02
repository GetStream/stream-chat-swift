//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Describes an object that can provide AVPlayer related updates.
protocol AudioPlayerObserving {
    /// Registers an observer with the player that will receive updates when the player's
    /// `AVPlayer.timeControlStatus` gets updated.
    /// - Parameters:
    ///   - player: The player from which we would like to receive updates
    ///   - block: The block to call once a `timeControlStatus` update occurs
    func addTimeControlStatusObserver(
        _ player: AVPlayer,
        using block: @escaping (AVPlayer.TimeControlStatus?) -> Void
    )

    /// Registers an observer that will periodically invoke the given block during playback to
    /// report changing time.
    /// - Parameters:
    ///   - player: The player from which we would like to receive updates
    ///   - interval: The interval at which we would like to receive updates
    ///   - queue: The queue on which the call to block will occur every time there is an update
    ///   - block: The block to call every time there is an update
    func addPeriodicTimeObserver(
        _ player: AVPlayer,
        forInterval interval: CMTime,
        queue: DispatchQueue?,
        using block: @escaping () -> Void
    )

    /// Registers and observer that will be called once the playback of an item stops
    /// - Parameters:
    ///   - queue: The queue on which the `stoppedPlaybackHandler` will be dispatched
    ///   - block: The block to call once a player's item has stopped
    func addStoppedPlaybackObserver(
        queue: OperationQueue?,
        using block: @escaping (AVPlayerItem) -> Void
    )
}

final class StreamPlayerObserver: AudioPlayerObserving {
    /// An observer token that is used to observe the ``AVPlayer.timeControlStatus`` of the player to receive
    /// updates when the state changes between playing and paused.
    private var timeControlStatusObserver: NSKeyValueObservation?

    /// A token referencing the periodicTimer that is registered on the player and is used to provide
    /// time-related metadata updates.
    private var periodicTimeObservationToken: Any?

    /// This block is called on deinit to remove any registered periodicTimeObserver
    ///
    /// According to the documentation we need to remove the periodicTimeObserver if we had
    /// registered one.
    /// https://developer.apple.com/documentation/avfoundation/avplayer/1385829-addperiodictimeobserverforinterv#return_value
    private var periodicTimeObservationCancellationBlock: (() -> Void)?

    /// An observer token that is used to reference the NotificationCenter registration, that is being used
    /// to get notifications when the player's playback has been stopped.
    private var stoppedPlaybackObservationToken: Any?

    /// The notificationCenter on which the ``playbackFinishedObserver`` will be registered on
    private let notificationCenter: NotificationCenter

    // MARK: - Lifecycle

    /// Creates a new instance of StreamPlayerObserver
    /// - Parameter notificationCenter: The notificationCenter on which the stoppedPlaybackObserver
    /// will be registered to listen for the `NSNotification.Name.AVPlayerItemDidPlayToEndTime`
    /// notifications.
    init(
        notificationCenter: NotificationCenter = .default
    ) {
        self.notificationCenter = notificationCenter
    }

    deinit {
        timeControlStatusObserver?.invalidate()
        periodicTimeObservationCancellationBlock?()
        stoppedPlaybackObservationToken.map { notificationCenter.removeObserver($0) }
    }

    // MARK: - AudioPlayerObserving

    func addTimeControlStatusObserver(
        _ player: AVPlayer,
        using block: @escaping (AVPlayer.TimeControlStatus?) -> Void
    ) {
        timeControlStatusObserver = player.observe(
            \.timeControlStatus,
            changeHandler: { player, _ in block(player.timeControlStatus) }
        )
    }

    func addPeriodicTimeObserver(
        _ player: AVPlayer,
        forInterval interval: CMTime,
        queue: DispatchQueue?,
        using block: @escaping () -> Void
    ) {
        periodicTimeObservationToken = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: queue,
            using: { _ in block() }
        )
        periodicTimeObservationCancellationBlock = { [weak player, periodicTimeObservationToken] in
            guard
                let player = player,
                let periodicTimeObservationToken = periodicTimeObservationToken
            else {
                return
            }
            player.removeTimeObserver(periodicTimeObservationToken)
        }
    }

    func addStoppedPlaybackObserver(
        queue: OperationQueue?,
        using block: @escaping (AVPlayerItem) -> Void
    ) {
        stoppedPlaybackObservationToken = notificationCenter.addObserver(
            forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: queue
        ) { notification in
            guard
                let playerItem = notification.object as? AVPlayerItem
            else {
                return
            }
            block(playerItem)
        }
    }
}
