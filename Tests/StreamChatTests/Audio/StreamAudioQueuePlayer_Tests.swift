//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StreamAudioQueuePlayer_Tests: XCTestCase {
    private var dataSource: MockAudioQueuePlayerDatasource!
    private var assetPropertyLoader: MockAssetPropertyLoader!
    private var playerObserver: MockAudioPlayerObserver!
    private var audioSessionConfigurator: MockAudioSessionConfigurator!
    private var appStateObserver: MockAppStateObserver!
    private var player: MockAVPlayer!
    private var subject: StreamAudioQueuePlayer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        dataSource = .init()
        assetPropertyLoader = .init()
        audioSessionConfigurator = .init()
        playerObserver = .init()
        appStateObserver = .init()
        player = .init()
        subject = .init(
            assetPropertyLoader: assetPropertyLoader,
            playerObserver: playerObserver,
            player: player,
            audioSessionConfigurator: audioSessionConfigurator,
            appStateObserver: appStateObserver
        )

        player.mockPlayerObserver = playerObserver
        subject.dataSource = dataSource
    }

    override func tearDownWithError() throws {
        subject = nil
        player = nil
        appStateObserver = nil
        audioSessionConfigurator = nil
        playerObserver = nil
        assetPropertyLoader = nil
        dataSource = nil
        try super.tearDownWithError()
    }

    // MARK: - playbackWillStop(_:)

    func test_playbackDidStop_dataSourceProvidesNoNextTrackURL_stopsPlayback() {
        let currentURL = URL.unique()
        assetPropertyLoader.loadPropertiesResult = .success(.init(url: currentURL))
        subject.loadAsset(from: currentURL)

        /// Simulate playback approaching stop
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: currentURL))

        XCTAssertTrue((dataSource.audioQueuePlayerNextAssetURLWasCalledWithAudioPlayer as? StreamAudioQueuePlayer) === subject)
        XCTAssertEqual(dataSource.audioQueuePlayerNextAssetURLWasCalledWithCurrentAssetURL, currentURL)
        XCTAssertTrue(player.pauseWasCalled)
    }

    func test_playbackDidStop_dataSourceProvidesNextTrackURL_loadsAsset() {
        let currentURL = URL.unique()
        let nextTrackURL = URL.unique()
        assetPropertyLoader.loadPropertiesResult = .success(.init(url: currentURL))
        subject.loadAsset(from: currentURL)
        /// Prepare for the second call
        player.replaceCurrentItemWasCalledWithItem = nil
        assetPropertyLoader.loadPropertiesResult = .success(.init(url: nextTrackURL))
        dataSource.audioQueuePlayerNextAssetURLResult = nextTrackURL

        /// Simulate playback approaching stop
        playerObserver.addStoppedPlaybackObserverWasCalledWithBlock?(.init(url: currentURL))

        XCTAssertTrue((dataSource.audioQueuePlayerNextAssetURLWasCalledWithAudioPlayer as? StreamAudioQueuePlayer) === subject)
        XCTAssertEqual(dataSource.audioQueuePlayerNextAssetURLWasCalledWithCurrentAssetURL, currentURL)
        XCTAssertEqual((player.replaceCurrentItemWasCalledWithItem?.asset as? AVURLAsset)?.url, nextTrackURL)
    }
}

private final class MockAudioQueuePlayerDatasource: AudioQueuePlayerDatasource {
    private(set) var audioQueuePlayerNextAssetURLWasCalledWithAudioPlayer: AudioPlaying?
    private(set) var audioQueuePlayerNextAssetURLWasCalledWithCurrentAssetURL: URL?
    var audioQueuePlayerNextAssetURLResult: URL?

    func audioQueuePlayerNextAssetURL(
        _ audioPlayer: AudioPlaying,
        currentAssetURL: URL?
    ) -> URL? {
        audioQueuePlayerNextAssetURLWasCalledWithAudioPlayer = audioPlayer
        audioQueuePlayerNextAssetURLWasCalledWithCurrentAssetURL = currentAssetURL
        return audioQueuePlayerNextAssetURLResult
    }
}
