//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Describes and object that can provide AVPlayer related updates.
public protocol AudioPlayerObserving {
    /// Registers an observer with the player that will receive updates when the player's
    /// ``timeControlStatus`` gets updated.
    /// - Parameters:
    /// player: The player from which we would like to received updates
    /// block: The block to call once a ``timeControlStatus`` update occurs
    func addTimeControlStatusObserver(
        _ player: AVPlayer,
        using block: @escaping (AVPlayer.TimeControlStatus?) -> Void
    )

    /// Registers an observer that will periodically invoke the given block during playback to
    /// report changing time.
    /// - Parameters:
    /// player: The player from which we would like to received updates
    /// interval: The interval at which we would like to receive updates
    /// queue: The queue on which the call to block will occur every time there is an update
    /// block: The block to call every time there is an update
    func addPeriodicTimeObserver(
        _ player: AVPlayer,
        forInterval interval: CMTime,
        queue: DispatchQueue?,
        using block: @escaping () -> Void
    )

    /// Registers and observer that will be called once the playback of an item stops
    /// - Parameters:
    /// queue: The queue on which the ``stoppedPlaybackHandler`` will be dispatched
    /// block: The block to call once a player's item has stopped
    func addStoppedPlaybackObserver(
        queue: OperationQueue?,
        using block: @escaping (AVPlayerItem) -> Void
    )
}

open class StreamPlayerObserver: AudioPlayerObserving {
    /// An observer token that is used to observe the ``timeControlStatus`` of the player to receive
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

    /// An observer token that tis used to reference the NotificationCenter registration, that is being used
    /// to get notifications when the player's playback has been stopped.
    private var stoppedPlaybackObservationToken: Any?

    /// The notificationCenter on which the ``playbackFinishedObserver`` will be registered one
    private let notificationCenter: NotificationCenter

    // MARK: - Lifecycle

    public init(
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

    open func addTimeControlStatusObserver(
        _ player: AVPlayer,
        using block: @escaping (AVPlayer.TimeControlStatus?) -> Void
    ) {
        timeControlStatusObserver = player.observe(
            \.timeControlStatus,
            changeHandler: { _, change in block(change.newValue) }
        )
    }

    open func addPeriodicTimeObserver(
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

    open func addStoppedPlaybackObserver(
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
