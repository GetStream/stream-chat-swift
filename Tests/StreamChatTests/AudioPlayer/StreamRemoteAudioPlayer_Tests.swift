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
            playerObserver.addPeriodicTimeObserverWasCalledWith?.interval,
            expectedInterval
        )
    }

    func test_init_addTimeControlStatusObserverWasCalledOnPlayerObserverWithExpectedValues() {
        XCTAssertEqual(
            playerObserver.addTimeControlStatusObserverWaCalledWith?.object,
            player
        )
    }

    func test_init_addStoppedPlaybackObserverWasCalledOnPlayerObserverWithExpectedValues() {
        XCTAssertNotNil(playerObserver.addStoppedPlaybackObserverWasCalledWith)
        XCTAssertNil(playerObserver.addStoppedPlaybackObserverWasCalledWith?.queue)
    }

    // MARK: - periodicTimerObserver

    func test_periodicTimerObserver_isSeekingIsFalse_delegateWasUpdatedWithExpectedContext() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(
            from: .init(string: "http://getstream.io"),
            andConnectDelegate: audioPlayerDelegate
        )

        player.rate = 2

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
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
            from: .init(string: "http://getstream.io"),
            andConnectDelegate: audioPlayerDelegate
        )
        subject.seek(to: 10)

        playerObserver.addPeriodicTimeObserverWasCalledWith?.block()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
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
        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.paused)

        XCTAssertNil(audioPlayerDelegate.didUpdateContextWasCalled?.context)
    }

//
    func test_timeControlStatusObserver_newStateIsPausedCurrentStateIsLoading_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.holdLoadProperties = true
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
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

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
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
        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: assetURL))

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.paused)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
            duration: 100,
            currentTime: 0,
            state: .stopped,
            rate: .zero,
            isSeeking: false
        ))
    }

    // MARK: newState: .playing

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsNotLoaded_delegateWasNotCalled() {
        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.playing)

        XCTAssertNil(audioPlayerDelegate.didUpdateContextWasCalled?.context)
    }

    func test_timeControlStatusObserver_newStateIsPlayingCurrentStateIsLoading_delegateWasCalledWithExpectedContext() {
        assetPropertyLoader.holdLoadProperties = true
        subject.loadAsset(
            from: assetURL,
            andConnectDelegate: audioPlayerDelegate
        )

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
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

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
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
        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: assetURL))

        playerObserver.addTimeControlStatusObserverWaCalledWith?.block(.playing)

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
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

        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: assetURL))

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
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

        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: .init(string: "http://getstream.io/2")!))

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, .init(
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

    func test_loadAsset_whenURLIsNil_willCallPauseUpdateTheContextReplaceCurrentItemButWillNotCallLoadProperty() {
        subject.loadAsset(from: nil, andConnectDelegate: audioPlayerDelegate)

        XCTAssertTrue(player.pauseWasCalled)
        XCTAssertEqual(subject.context, .init(
            duration: 0,
            currentTime: 0,
            state: .stopped,
            rate: .zero,
            isSeeking: false
        ))
        XCTAssertTrue(player.replaceCurrentItemWasCalled)
        XCTAssertNil(player.replaceCurrentItemWasCalledWithItem)
        XCTAssertNil(subject.delegate)
    }

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
        XCTAssertEqual(assetPropertyLoader.loadPropertiesWasCalledWith?.properties.first?.name, "duration")
        XCTAssertEqual((assetPropertyLoader.loadPropertiesWasCalledWith?.asset as? AVURLAsset)?.url, assetURL)
        XCTAssertTrue(player.playWasCalled)
        XCTAssertTrue((audioPlayerDelegate.didUpdateContextWasCalled?.player as? StreamRemoteAudioPlayer) === subject)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context, expectedContext)
    }

    func test_loadAsset_whenURLIsNotNil_assetLoadFail_willCallPauseUpdateTheContextReplaceCurrentItemLoadPropertyAndPlay() {
        let url = assetURL
        subject.play()
        player.playWasCalled = false
        assetPropertyLoader.loadPropertiesResult = .failure(.init(failedProperties: [], cancelledProperties: []))

        subject.loadAsset(from: url, andConnectDelegate: audioPlayerDelegate)

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
        XCTAssertEqual(assetPropertyLoader.loadPropertiesWasCalledWith?.properties.first?.name, "duration")
        XCTAssertEqual((assetPropertyLoader.loadPropertiesWasCalledWith?.asset as? AVURLAsset)?.url, assetURL)
        XCTAssertFalse(player.playWasCalled)
    }

    func test_loadAsset_whenURLSameAsCurrentItemURLAndContextStateIsPaused_willNotCallAssetLoaderWillCallPlayUpdatesStateAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)
        subject.pause()
        assetPropertyLoader.loadPropertiesWasCalledWith = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.loadAsset(from: assetURL, andConnectDelegate: secondDelegate)

        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWith)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalled?.context, .init(
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
        playerObserver.addStoppedPlaybackObserverWasCalledWith?.block(.init(url: assetURL))
        assetPropertyLoader.loadPropertiesWasCalledWith = nil
        player.replaceCurrentItemWasCalledWithItem = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.loadAsset(from: assetURL, andConnectDelegate: secondDelegate)

        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWith)
        XCTAssertEqual((player.replaceCurrentItemWasCalledWithItem?.asset as? AVURLAsset)?.url, assetURL)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalled?.context, .init(
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
        assetPropertyLoader.loadPropertiesWasCalledWith = nil
        player.replaceCurrentItemWasCalledWithItem = nil
        let secondDelegate = MockAudioPlayerDelegate()

        subject.loadAsset(from: assetURL, andConnectDelegate: secondDelegate)

        XCTAssertNil(assetPropertyLoader.loadPropertiesWasCalledWith)
        XCTAssertNil(player.replaceCurrentItemWasCalledWithItem)
        XCTAssertFalse(player.playWasCalled)
        XCTAssertEqual(secondDelegate.didUpdateContextWasCalled?.context, .init(
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

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .playing)
        XCTAssertTrue(player.playWasCalled)
    }

    // MARK: - pause

    func test_pause_callsPauseOnPlayerAndUpdatesContextAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        subject.pause()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .paused)
        XCTAssertTrue(player.pauseWasCalled)
    }

    // MARK: - stop

    func test_stop_callsPauseOnPlayerAndUpdatesContextAndDelegate() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        subject.stop()

        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .stopped)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.duration, TimeInterval(100))
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.currentTime, 0)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.rate, .zero)
        XCTAssertFalse(audioPlayerDelegate.didUpdateContextWasCalled?.context.isSeeking ?? true)
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
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .paused)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.currentTime, 50)
        XCTAssertTrue(audioPlayerDelegate.didUpdateContextWasCalled?.context.isSeeking ?? false)
    }

    func test_seek_seekWasCalledAndTheRequestWasNotInterrupted_seekWasCalledOnPlayerAndContextWasUpdatedSuccessfully() {
        mockAsset.stubProperty(\.duration, with: assetDuration)
        assetPropertyLoader.loadPropertiesResult = .success(mockAsset)
        subject.loadAsset(from: assetURL, andConnectDelegate: audioPlayerDelegate)

        subject.seek(to: 50)

        XCTAssertTrue(player.playWasCalled)
        XCTAssertEqual(audioPlayerDelegate.didUpdateContextWasCalled?.context.state, .playing)
        XCTAssertFalse(audioPlayerDelegate.didUpdateContextWasCalled?.context.isSeeking ?? true)
        XCTAssertEqual(player.seekWasCalledWith?.time, CMTimeMakeWithSeconds(50, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        XCTAssertEqual(player.seekWasCalledWith?.toleranceBefore, .zero)
        XCTAssertEqual(player.seekWasCalledWith?.toleranceAfter, .zero)
    }
}

extension StreamRemoteAudioPlayer_Tests {
    private class MockAVPlayer: AVPlayer {
        var playWasCalled = false

        private(set) var pauseWasCalled = false

        private(set) var replaceCurrentItemWasCalled = false
        var replaceCurrentItemWasCalledWithItem: AVPlayerItem?

        private(set) var rateWasUpdatedTo: Float?

        private(set) var seekWasCalledWith: (time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime)?
        public var holdSeekCompletion = false

        override var rate: Float {
            didSet {
                rateWasUpdatedTo = rate
                mockPlayerObserver?.addPeriodicTimeObserverWasCalledWith?.block()
            }
        }

        var mockPlayerObserver: MockAudioPlayerObserver?

        override func play() {
            playWasCalled = true
            super.play()
            mockPlayerObserver?.addTimeControlStatusObserverWaCalledWith?.block(.playing)
        }

        override func pause() {
            pauseWasCalled = true
            super.pause()
            mockPlayerObserver?.addTimeControlStatusObserverWaCalledWith?.block(.paused)
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
            seekWasCalledWith = (time, toleranceBefore, toleranceAfter)
            super.seek(
                to: time,
                toleranceBefore: toleranceBefore,
                toleranceAfter: toleranceAfter,
                completionHandler: { _ in completionHandler(!self.holdSeekCompletion) }
            )
        }
    }

    private class MockAssetPropertyLoader: AssetPropertyLoading {
        var loadPropertiesWasCalledWith: (properties: [AssetProperty], asset: AVAsset)?
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
            loadPropertiesWasCalledWith = (properties, asset)
            completion(loadPropertiesResult!.map { $0 as! Asset })
        }
    }

    private class MockAudioPlayerObserver: AudioPlayerObserving {
        private(set) var addTimeControlStatusObserverWaCalledWith: (object: AVPlayer, block: (AVPlayer.TimeControlStatus?) -> Void)?
        private(set) var addPeriodicTimeObserverWasCalledWith: (player: AVPlayer, interval: CMTime, queue: DispatchQueue?, block: () -> Void)?
        private(set) var addStoppedPlaybackObserverWasCalledWith: (queue: OperationQueue?, block: (AVPlayerItem) -> Void)?

        func addTimeControlStatusObserver(
            _ player: AVPlayer,
            using block: @escaping (AVPlayer.TimeControlStatus?) -> Void
        ) {
            addTimeControlStatusObserverWaCalledWith = (player, block)
        }

        func addPeriodicTimeObserver(
            _ player: AVPlayer,
            forInterval interval: CMTime,
            queue: DispatchQueue?,
            using block: @escaping () -> Void
        ) {
            addPeriodicTimeObserverWasCalledWith = (player, interval, queue, block)
        }

        func addStoppedPlaybackObserver(
            queue: OperationQueue?,
            using block: @escaping (AVPlayerItem) -> Void
        ) {
            addStoppedPlaybackObserverWasCalledWith = (queue, block)
        }
    }
}
