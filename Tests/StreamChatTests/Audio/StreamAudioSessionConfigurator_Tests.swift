//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StreamAudioSessionConfigurator_Tests: XCTestCase {
    private lazy var stubAudioSession: StubAVAudioSession! = .init()
    private lazy var subject: StreamAudioSessionConfigurator! = .init(stubAudioSession)
    private lazy var genericError: Error! = NSError(domain: "test", code: 11)

    override func tearDown() {
        subject = nil
        stubAudioSession = nil
        genericError = nil
        super.tearDown()
    }

    // MARK: - activateRecordingSession

    func test_activateRecordingSession_setCategoryFailedToComplete() {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)
        stubAudioSession.setCategoryResult = .failure(genericError)

        XCTAssertThrowsError(try subject.activateRecordingSession(), genericError)
    }

    func test_activateRecordingSession_setCategoryCompletedSuccessfully() throws {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)

        try subject.activateRecordingSession()

        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithCategory, .playAndRecord)
        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithMode, .spokenAudio)
        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithPolicy, .default)
        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithOptions, [.allowBluetooth])
    }

    func test_activateRecordingSession_setActiveFailed() {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)
        stubAudioSession.setActiveResult = .failure(genericError)

        XCTAssertThrowsError(try subject.activateRecordingSession(), genericError)
        XCTAssertTrue(stubAudioSession.setActiveWasCalledWithActive ?? false)
    }

    func test_activateRecordingSession_setActiveCompletedSuccessfully() throws {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)

        try subject.activateRecordingSession()
        XCTAssertTrue(stubAudioSession.setActiveWasCalledWithActive ?? false)
    }

    // MARK: - deactivateRecordingSession

    func test_deactivateRecordingSession_categoryIsRecord_setActiveCompletedSuccesfully() throws {
        stubAudioSession.stubProperty(\.category, with: .record)

        try subject.deactivateRecordingSession()

        XCTAssertFalse(stubAudioSession.setActiveWasCalledWithActive ?? true)
    }

    func test_deactivateRecordingSession_categoryIsRecord_setActiveFailed() throws {
        stubAudioSession.stubProperty(\.category, with: .record)
        stubAudioSession.setActiveResult = .failure(genericError)

        XCTAssertThrowsError(try subject.deactivateRecordingSession(), genericError)
        XCTAssertFalse(stubAudioSession.setActiveWasCalledWithActive ?? true)
    }

    func test_deactivateRecordingSession_categoryIsPlayAndRecord_setActiveCompletedSuccesfully() throws {
        stubAudioSession.stubProperty(\.category, with: .playAndRecord)

        try subject.deactivateRecordingSession()

        XCTAssertFalse(stubAudioSession.setActiveWasCalledWithActive ?? true)
    }

    func test_deactivateRecordingSession_categoryIsPlayAndRecord_setActiveFailed() throws {
        stubAudioSession.stubProperty(\.category, with: .playAndRecord)
        stubAudioSession.setActiveResult = .failure(genericError)

        XCTAssertThrowsError(try subject.deactivateRecordingSession(), genericError)
        XCTAssertFalse(stubAudioSession.setActiveWasCalledWithActive ?? true)
    }

    // MARK: - activatePlaybackSession

    func test_activatePlaybackSession_setCategoryFailedToComplete() {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)
        stubAudioSession.setCategoryResult = .failure(genericError)

        XCTAssertThrowsError(try subject.activatePlaybackSession(), genericError)
    }

    func test_activatePlaybackSession_setCategoryCompletedSuccessfully() throws {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)

        try subject.activatePlaybackSession()

        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithCategory, .playAndRecord)
        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithMode, .default)
        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithPolicy, .default)
        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithOptions, [.defaultToSpeaker, .allowBluetooth])
    }

    func test_activatePlaybackSession_setActiveFailed() {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)
        stubAudioSession.setActiveResult = .failure(genericError)

        XCTAssertThrowsError(try subject.activatePlaybackSession(), genericError)
        XCTAssertTrue(stubAudioSession.setActiveWasCalledWithActive ?? false)
    }

    func test_activatePlaybackSession_setActiveCompletedSuccessfully() throws {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)

        try subject.activatePlaybackSession()
        XCTAssertTrue(stubAudioSession.setActiveWasCalledWithActive ?? false)
    }

    // MARK: - deactivatePlaybackSession

    func test_deactivatePlaybackSession_categoryIsPlayback_setActiveCompletedSuccesfully() throws {
        stubAudioSession.stubProperty(\.category, with: .playback)

        try subject.deactivatePlaybackSession()

        XCTAssertFalse(stubAudioSession.setActiveWasCalledWithActive ?? true)
    }

    func test_deactivatePlaybackSession_categoryIsPlayback_setActiveFailed() throws {
        stubAudioSession.stubProperty(\.category, with: .playback)
        stubAudioSession.setActiveResult = .failure(genericError)

        XCTAssertThrowsError(try subject.deactivatePlaybackSession(), genericError)
        XCTAssertFalse(stubAudioSession.setActiveWasCalledWithActive ?? true)
    }

    func test_deactivatePlaybackSession_categoryIsPlayAndRecord_setActiveCompletedSuccesfully() throws {
        stubAudioSession.stubProperty(\.category, with: .playAndRecord)

        try subject.deactivatePlaybackSession()

        XCTAssertFalse(stubAudioSession.setActiveWasCalledWithActive ?? true)
    }

    func test_deactivatePlaybackSession_categoryIsPlayAndRecord_setActiveFailed() throws {
        stubAudioSession.stubProperty(\.category, with: .playAndRecord)
        stubAudioSession.setActiveResult = .failure(genericError)

        XCTAssertThrowsError(try subject.deactivatePlaybackSession(), genericError)
        XCTAssertFalse(stubAudioSession.setActiveWasCalledWithActive ?? true)
    }

    // MARK: - requestRecordPermission

    func test_requestRecordPermission_callsAudioSession() {
        subject.requestRecordPermission { _ in }

        XCTAssertNotNil(stubAudioSession.requestRecordPermissionWasCalledWithResponse)
    }
}

@dynamicMemberLookup
private final class StubAVAudioSession: AudioSessionProtocol, Stub {
    var stubbedProperties: [String: Any] = [:]

    @objc var category: AVAudioSession.Category { self[dynamicMember: \.category] }

    private(set) var setCategoryWasCalledWithCategory: AVAudioSession.Category?
    private(set) var setCategoryWasCalledWithMode: AVAudioSession.Mode?
    private(set) var setCategoryWasCalledWithPolicy: AVAudioSession.RouteSharingPolicy?
    private(set) var setCategoryWasCalledWithOptions: AVAudioSession.CategoryOptions?
    var setCategoryResult: Result<Void, Error> = .success(())

    private(set) var setActiveWasCalledWithActive: Bool?
    var setActiveResult: Result<Void, Error> = .success(())

    private(set) var requestRecordPermissionWasCalledWithResponse: ((Bool) -> Void)?
    var requestRecordPermissionResult: Bool = false

    private(set) var overrideOutputAudioPortWasCalledWithPortOverride: AVAudioSession.PortOverride?
    var overrideOutputAudioPortResult: Result<Void, Error> = .success(())

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        policy: AVAudioSession.RouteSharingPolicy,
        options: AVAudioSession.CategoryOptions = []
    ) throws {
        setCategoryWasCalledWithCategory = category
        setCategoryWasCalledWithMode = mode
        setCategoryWasCalledWithPolicy = policy
        setCategoryWasCalledWithOptions = options

        switch setCategoryResult {
        case .success:
            break
        case let .failure(error):
            throw error
        }
    }

    func setActive(
        _ active: Bool,
        options: AVAudioSession.SetActiveOptions = []
    ) throws {
        setActiveWasCalledWithActive = active

        switch setActiveResult {
        case .success:
            break
        case let .failure(error):
            throw error
        }
    }

    func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
        requestRecordPermissionWasCalledWithResponse = response
        response(requestRecordPermissionResult)
    }

    func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws {
        overrideOutputAudioPortWasCalledWithPortOverride = portOverride
        switch overrideOutputAudioPortResult {
        case .success:
            break
        case let .failure(error):
            throw error
        }
    }
}
