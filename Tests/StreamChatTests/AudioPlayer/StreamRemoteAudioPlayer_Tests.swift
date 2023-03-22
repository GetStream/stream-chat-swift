//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamChat
import StreamChatTestTools
import XCTest

final class StreamRemoteAudioPlayer_Tests: XCTestCase {
    private var audioPlayerDelegate: MockAudioPlayerDelegate!
    private var assetPropertyLoader: MockAssetPropertyLoader!
    private var playerObserver: MockAudioPlayerObserver!
    private var player: MockAVPlayer!
    private var subject: StreamRemoteAudioPlayer!

    private lazy var assetURL: URL! = URL(string: "http://getstream.io")!
    private lazy var mockAsset: MockAVURLAsset! = .init(url: assetURL)
    private lazy var assetDuration: CMTime! = CMTime(seconds: 100, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

    override func setUpWithError() throws {
        try super.setUpWithError()
        audioPlayerDelegate = .init()
        assetPropertyLoader = .init()
        playerObserver = .init()
        player = .init()
        subject = .init(
            assetPropertyLoader: assetPropertyLoader,
            playerObserver: playerObserver,
            player: player
        )

        player.mockPlayerObserver = playerObserver
    }

    override func tearDownWithError() throws {
        subject = nil
        player = nil
        playerObserver = nil
        assetPropertyLoader = nil
        audioPlayerDelegate = nil
        assetDuration = nil
        mockAsset = nil
        assetURL = nil
        try super.tearDownWithError()
    }

    // MARK: - init

    func test_init_addPeriodicTimeObserverWasCalledOnPlayerObserverWithExpectedInterval() {
        let expectedInterval = CMTime(
            seconds: 0.1,
            preferredTimescale: CMTimeScale(NSEC_PER_SEC)
        )

        XCTAssertEqual(
            playerObserver.addPeriodicTimeObserverWasCalledWithInterval,
            expectedInterval
        )
    }

    func test_init_addTimeControlStatusObserverWasCalledOnPlayerObserverWithExpectedValues() {
        XCTAssertEqual(
            playerObserver.addTimeControlStatusObserverWaCalledWithObject,
            player
        )
    }

    func test_init_addStoppedPlaybackObserverWasCalledOnPlayerObserverWithExpectedValues() {
        XCTAssertNotNil(playerObserver.addStoppedPlaybackObserverWasCalledWithBlock)
        XCTAssertNil(playerObserver.addStoppedPlaybackObserverWasCalledWithQueue)
    }

    // MARK: - periodicTimerObserver

    func test_periodicTimerObserver_isSeekingIsFalse_delegateWasUpdatedWithExpectedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )

        player.rate = 2

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .double,
            isSeeking: false
        ))
    }

    func test_periodicTimerObserver_isSeekingIsTrue_theContextWasNotUpdated() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        player.holdSeekCompletion = true
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )
        subject.seek(to: 10)

        playerObserver.addPeriodicTimeObserverWasCalledWithBlock?()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 10,
            state: .paused,
            rate: .zero,
            isSeeking: true
        ))
    }

    // MARK: - timeControlStatusObserver

    // MARK: newState: .paused

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsNotLoaded_delegateWasNotCalled() {
        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.paused)

        XCTAssertNil(audioPlayerDelegate.didUpdateContextWasCalledWithContext)
    }

//
    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsLoading_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.holdLoadProperties = true
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 0,
            currentTime: 0,
            state: .paused,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsPlaying_delegateWasCalledWithExpectedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .paused,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsStopped_delegateWasNotCalled() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: assetURL))

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .stopped,
            rate: .zero,
            isSeeking: false
        ))
    }

    // MARK: newState: .playing

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsNotLoaded_delegateWasNotCalled() {
        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.playing)

        XCTAssertNil(audioPlayerDelegate.didUpdateContextWasCalledWithContext)
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsLoading_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.holdLoadProperties = true
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 0,
            currentTime: 0,
            state: .playing,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsPaused_delegateWasCalledWithExpectedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )
        subject.pause()

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsStopped_delegateWasNotCalled() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: assetURL))

        playerObserver.addTimeControlStatusObserverWaCalledWithBlock?(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .zero,
            isSeeking: false
        ))
    }

    // MARK: - stoppedPlaybackObserver

    func test_stoppedPlaybackObserver_currentItemIsTheSameAsTheStoppedOne_delegateWasCalledWithUpdatedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: assetURL))

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .stopped,
            rate: .zero,
            isSeeking: false
        ))
    }

    func test_stoppedPlaybackObserver_currentItemIsNotTheSameAsTheStoppedOne_delegateWasNotCalledWithUpdatedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: .init(string: "http://getstream.io/2")!))

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    // MARK: - playbackContext

    func test_playbackContext_URLMatchesCurrentItemsURL_returnsExpectedResult() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        XCTAssertEqual(
            subject.playbackContext(for: assetURL),
            .init(
                duration: 100,
                currentTime: 0,
                state: .playing,
                rate: .normal,
                isSeeking: false
            )
        )
    }

    func test_playbackContext_URLDoesNotMatchCurrentItemsURL_returnsNotLoaded() {
        XCTAssertEqual(subject.playbackContext(for: assetURL), .notLoaded)
    }

    // MARK: - loadAsset

    func test_loadAsset_whenURLIsNotNil_assetLoadSucceeds_willCallPauseUpdateTheContextReplaceCurrentItemLoadPropertyAndPlay() {
        subject.play()
        player.playWasCalled = false
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        let expectedContext = AudioPlaybackContext(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        )

        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        XCTAssertTrue(player.pauseWasCalled)
        XCTAssertEqual(subject.context, expectedContext)
        XCTAssertTrue(player.replaceCurrentItemWasCalled)
        XCTAssertEqual((player.replaceCurrentItemWasCalledWithItem?.asset as? AVURLAsset)?.url, assetURL)
        XCTAssertTrue(subject.delegate === audioPlayerDelegate)
        XCTAssertEqual(assetPropertyLoader.loadPropertiesWasCalledWithProperties?.first?.name, "duration")
        XCTAssertEqual((assetPropertyLoader.loadPropertiesWasCalledWithAsset as? AVURLAsset)?.url, assetURL)
        XCTAssertTrue(player.playWasCalled)
        XCTAssertTrue((audioPlayerDelegate.didUpdateContextWasCalledWithPlayer as? StreamRemoteAudioPlayer) === subject)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext, expectedContext)
    }

    func test_loadAsset_whenURLIsNotNil_assetLoadFail_willCallPauseUpdateTheContextReplaceCurrentItemLoadPropertyAndPlay() {
        subject.play()
        player.playWasCalled = false
        assetPropertyLoader.loadPropertiesResult = .failure(.init(failedProperties: [], cancelledProperties: []))

        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        XCTAssertTrue(player.pauseWasCalled)
        XCTAssertEqual(subject.context, .init(
            duration: 0,
            currentTime: 0,
            state: .notLoaded,
            rate: .zero,
            isSeeking: false
        ))
        XCTAssertTrue(player.replaceCurrentItemWasCalled)
        XCTAssertNil(player.replaceCurrentItemWasCalledWithItem)
        XCTAssertTrue(subject.delegate === audioPlayerDelegate)
        XCTAssertEqual(assetPropertyLoader.loadPropertiesWasCalledWithProperties?.first?.name, "duration")
        XCTAssertEqual((assetPropertyLoader.loadPropertiesWasCalledWithAsset as? AVURLAsset)?.url, assetURL)
        XCTAssertFalse(player.playWasCalled)
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsPaused_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)
        subject.pause()
        assetPropertyLoader.loadPropertiesWasCalledWithProperties = nil
        assetPropertyLoader.loadPropertiesWasCalledWithAsset = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.loadAsset(from: assetURL, andConnectDelegate: secondDelegate)

        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithProperties)
        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithAsset)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsStopped_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: assetURL))
        assetPropertyLoader.loadPropertiesWasCalledWithProperties = nil
        assetPropertyLoader.loadPropertiesWasCalledWithAsset = nil
        player.replaceCurrentItemWasCalledWithItem = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.loadAsset(from: assetURL, andConnectDelegate: secondDelegate)

        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithProperties)
        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithAsset)
        XCTAssertEqual((player.replaceCurrentItemWasCalledWithItem?.asset as? AVURLAsset)?.url, assetURL)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsPlaying_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)
        player.playWasCalled = false
        assetPropertyLoader.loadPropertiesWasCalledWithProperties = nil
        assetPropertyLoader.loadPropertiesWasCalledWithAsset = nil
        player.replaceCurrentItemWasCalledWithItem = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.loadAsset(from: assetURL, andConnectDelegate: secondDelegate)

        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithProperties)
        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWithAsset)
        XCTAssertNil(player.replaceCurrentItemWasCalledWithItem)
        XCTAssertFalse(player.playWasCalled)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalledWithContext, .init(
            duration: 100,
            currentTime: 0,
            state: .playing,
            rate: .normal,
            isSeeking: false
        ))
    }

    // MARK: - play

    func test_play_callsPlayOnPlayerAndUpdatesContextAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)
        player.pause()
        player.playWasCalled = false

        subject.play()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .playing)
        XCTAssertTrue(player.playWasCalled)
    }

    // MARK: - pause

    func test_pause_callsPauseOnPlayerAndUpdatesContextAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        subject.pause()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .paused)
        XCTAssertTrue(player.pauseWasCalled)
    }

    // MARK: - stop

    func test_stop_callsPauseOnPlayerAndUpdatesContextAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        subject.stop()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .stopped)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.duration, TimeInterval(100))
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.currentTime, 0)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.rate, .zero)
        XCTAssertFalse(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.isSeeking ?? true)
        XCTAssertTrue(player.pauseWasCalled)
    }

    // MARK: - updateRate

    func test_updateRate_updatesPlayerRate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        subject.updateRate(.double) // This call will change the rate to 2
        XCTAssertEqual(player.rateWasUpdatedTo, 2)

        subject.updateRate(.half) // This call will change the rate to 0.5
        XCTAssertEqual(player.rateWasUpdatedTo, 0.5)

        subject.updateRate(.normal) // This call will change the rate to 1
        XCTAssertEqual(player.rateWasUpdatedTo, 1)

        subject.updateRate(.double) // This call will change the rate to 2
        XCTAssertEqual(player.rateWasUpdatedTo, 2)
    }

    // MARK: - seek(to:)

    func test_seek_seekWasInterrupted_willCallPauseAndUpdateTheContextAsExpected() {
        subject = .init(
            assetPropertyLoader: assetPropertyLoader,
            playerObserver: playerObserver,
            player: player
        )

        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)
        player.holdSeekCompletion = true

        subject.seek(to: 50)

        XCTAssertTrue(player.playWasCalled)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .paused)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.currentTime, 50)
        XCTAssertTrue(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.isSeeking ?? false)
    }

    func test_seek_seekWasCalledAndTheRequestWasNotInterrupted_seekWasCalledOnPlayerAndContextWasUpdatedSuccessfully() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        subject.seek(to: 50)

        XCTAssertTrue(player.playWasCalled)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.state, .playing)
        XCTAssertFalse(audioPlayerDelegate.didUpdateContextWasCalledWithContext?.isSeeking ?? true)
        XCTAssertEqual(player.seekWasCalledWithTime, CMTimeMakeWithSeconds(50, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        XCTAssertEqual(player.seekWasCalledWithToleranceBefore, .zero)
        XCTAssertEqual(player.seekWasCalledWithToleranceAfter, .zero)
    }
}

extension StreamRemoteAudioPlayer_Tests {
    private class MockAVPlayer: AVPlayer {
        var playWasCalled = false

        private(set) var pauseWasCalled = false

        private(set) var replaceCurrentItemWasCalled = false
        var replaceCurrentItemWasCalledWithItem: AVPlayerItem?

        private(set) var rateWasUpdatedTo: Float?

        private(set) var seekWasCalledWithTime: CMTime?
        private(set) var seekWasCalledWithToleranceBefore: CMTime?
        private(set) var seekWasCalledWithToleranceAfter: CMTime?
        public var holdSeekCompletion = false

        override var rate: Float {
            didSet {
                rateWasUpdatedTo = rate
                mockPlayerObserver?.addPeriodicTimeObserverWasCalledWithBlock?()
            }
        }

        var mockPlayerObserver: MockAudioPlayerObserver?

        override func play() {
            playWasCalled = true
            super.play()
            mockPlayerObserver?.addTimeControlStatusObserverWaCalledWithBlock?(.playing)
        }

        override func pause() {
            pauseWasCalled = true
            super.pause()
            mockPlayerObserver?.addTimeControlStatusObserverWaCalledWithBlock?(.paused)
        }

        override func replaceCurrentItem(
            with item: AVPlayerItem?
        ) {
            replaceCurrentItemWasCalled = true
            replaceCurrentItemWasCalledWithItem = item
            super.replaceCurrentItem(with: item)
        }

        override func seek(
            to time: CMTime,
            toleranceBefore: CMTime,
            toleranceAfter: CMTime,
            completionHandler: @escaping (Bool) -> Void
        ) {
            seekWasCalledWithTime = time
            seekWasCalledWithToleranceBefore = toleranceBefore
            seekWasCalledWithToleranceAfter = toleranceAfter
            super.seek(
                to: time,
                toleranceBefore: toleranceBefore,
                toleranceAfter: toleranceAfter,
                completionHandler: { _ in completionHandler(!self.holdSeekCompletion) }
            )
        }
    }

    private class MockAssetPropertyLoader: AssetPropertyLoading {
        var loadPropertiesWasCalledWithProperties: [AssetProperty]?
        var loadPropertiesWasCalledWithAsset: AVAsset?
        var loadPropertiesResult: Result<AVAsset, AssetPropertyLoadingCompositeError>?
        var holdLoadProperties = false

        func loadProperties<Asset>(
            _ properties: [AssetProperty],
            of asset: Asset,
            completion: @escaping (Result<Asset, AssetPropertyLoadingCompositeError>) -> Void
        ) where Asset: AVAsset {
            guard holdLoadProperties == false else {
                return
            }
            loadPropertiesWasCalledWithProperties = properties
            loadPropertiesWasCalledWithAsset = asset
            completion(loadPropertiesResult!.map { $0 as! Asset })
        }
    }

    private class MockAudioPlayerObserver: AudioPlayerObserving {
        private(set) var addTimeControlStatusObserverWaCalledWithObject: AVPlayer?
        private(set) var addTimeControlStatusObserverWaCalledWithBlock: ((AVPlayer.TimeControlStatus?) -> Void)?

        private(set) var addPeriodicTimeObserverWasCalledWithPlayer: AVPlayer?
        private(set) var addPeriodicTimeObserverWasCalledWithInterval: CMTime?
        private(set) var addPeriodicTimeObserverWasCalledWithQueue: DispatchQueue?
        private(set) var addPeriodicTimeObserverWasCalledWithBlock: (() -> Void)?

        private(set) var addStoppedPlaybackObserverWasCalledWithQueue: OperationQueue?
        private(set) var addStoppedPlaybackObserverWasCalledWithBlock: ((AVPlayerItem) -> Void)?

        func addTimeControlStatusObserver(
            _ player: AVPlayer,
            using block: @escaping (AVPlayer.TimeControlStatus?) -> Void
        ) {
            addTimeControlStatusObserverWaCalledWithObject = player
            addTimeControlStatusObserverWaCalledWithBlock = block
        }

        func addPeriodicTimeObserver(
            _ player: AVPlayer,
            forInterval interval: CMTime,
            queue: DispatchQueue?,
            using block: @escaping () -> Void
        ) {
            addPeriodicTimeObserverWasCalledWithPlayer = player
            addPeriodicTimeObserverWasCalledWithInterval = interval
            addPeriodicTimeObserverWasCalledWithQueue = queue
            addPeriodicTimeObserverWasCalledWithBlock = block
        }

        func addStoppedPlaybackObserver(
            queue: OperationQueue?,
            using block: @escaping (AVPlayerItem) -> Void
        ) {
            addStoppedPlaybackObserverWasCalledWithQueue = queue
            addStoppedPlaybackObserverWasCalledWithBlock = block
        }
    }
}
