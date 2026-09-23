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
        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithOptions, [.allowBluetoothDevice])
    }

    func test_activateRecordingSession_setActiveFailed_reportsTheErrorOnTheCompletion() throws {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)
        stubAudioSession.setActiveResult = .failure(genericError)

        let error = try waitForSessionCompletion { try subject.activateRecordingSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, true)
        XCTAssertEqual(error as NSError?, genericError as NSError?)
    }

    func test_activateRecordingSession_setActiveCompletedSuccessfully() throws {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)

        let error = try waitForSessionCompletion { try subject.activateRecordingSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, true)
        XCTAssertNil(error)
    }

    // MARK: - deactivateRecordingSession

    func test_deactivateRecordingSession_categoryIsRecord_setActiveCompletedSuccesfully() throws {
        stubAudioSession.stubProperty(\.category, with: .record)

        let error = try waitForSessionCompletion { try subject.deactivateRecordingSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, false)
        XCTAssertNil(error)
    }

    func test_deactivateRecordingSession_categoryIsRecord_setActiveFailed_reportsTheErrorOnTheCompletion() throws {
        stubAudioSession.stubProperty(\.category, with: .record)
        stubAudioSession.setActiveResult = .failure(genericError)

        let error = try waitForSessionCompletion { try subject.deactivateRecordingSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, false)
        XCTAssertEqual(error as NSError?, genericError as NSError?)
    }

    func test_deactivateRecordingSession_categoryIsPlayAndRecord_setActiveCompletedSuccesfully() throws {
        stubAudioSession.stubProperty(\.category, with: .playAndRecord)

        let error = try waitForSessionCompletion { try subject.deactivateRecordingSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, false)
        XCTAssertNil(error)
    }

    func test_deactivateRecordingSession_categoryIsPlayAndRecord_setActiveFailed_reportsTheErrorOnTheCompletion() throws {
        stubAudioSession.stubProperty(\.category, with: .playAndRecord)
        stubAudioSession.setActiveResult = .failure(genericError)

        let error = try waitForSessionCompletion { try subject.deactivateRecordingSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, false)
        XCTAssertEqual(error as NSError?, genericError as NSError?)
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
        XCTAssertEqual(stubAudioSession.setCategoryWasCalledWithOptions, [.defaultToSpeaker, .allowBluetoothDevice])
    }

    func test_activatePlaybackSession_setActiveFailed_reportsTheErrorOnTheCompletion() throws {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)
        stubAudioSession.setActiveResult = .failure(genericError)

        let error = try waitForSessionCompletion { try subject.activatePlaybackSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, true)
        XCTAssertEqual(error as NSError?, genericError as NSError?)
    }

    func test_activatePlaybackSession_setActiveCompletedSuccessfully() throws {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)

        let error = try waitForSessionCompletion { try subject.activatePlaybackSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, true)
        XCTAssertNil(error)
    }

    // MARK: - deactivatePlaybackSession

    func test_deactivatePlaybackSession_categoryIsPlayback_setActiveCompletedSuccesfully() throws {
        stubAudioSession.stubProperty(\.category, with: .playback)

        let error = try waitForSessionCompletion { try subject.deactivatePlaybackSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, false)
        XCTAssertNil(error)
    }

    func test_deactivatePlaybackSession_categoryIsPlayback_setActiveFailed_reportsTheErrorOnTheCompletion() throws {
        stubAudioSession.stubProperty(\.category, with: .playback)
        stubAudioSession.setActiveResult = .failure(genericError)

        let error = try waitForSessionCompletion { try subject.deactivatePlaybackSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, false)
        XCTAssertEqual(error as NSError?, genericError as NSError?)
    }

    func test_deactivatePlaybackSession_categoryIsPlayAndRecord_setActiveCompletedSuccesfully() throws {
        stubAudioSession.stubProperty(\.category, with: .playAndRecord)

        let error = try waitForSessionCompletion { try subject.deactivatePlaybackSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, false)
        XCTAssertNil(error)
    }

    func test_deactivatePlaybackSession_categoryIsPlayAndRecord_setActiveFailed_reportsTheErrorOnTheCompletion() throws {
        stubAudioSession.stubProperty(\.category, with: .playAndRecord)
        stubAudioSession.setActiveResult = .failure(genericError)

        let error = try waitForSessionCompletion { try subject.deactivatePlaybackSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledWithActive, false)
        XCTAssertEqual(error as NSError?, genericError as NSError?)
    }

    // MARK: - Main thread

    func test_activatePlaybackSession_setActiveIsNotCalledOnTheMainThread() throws {
        stubAudioSession.stubProperty(\.category, with: .soloAmbient)

        _ = try waitForSessionCompletion { try subject.activatePlaybackSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledOnMainThread, false)
    }

    func test_deactivatePlaybackSession_setActiveIsNotCalledOnTheMainThread() throws {
        stubAudioSession.stubProperty(\.category, with: .playAndRecord)

        _ = try waitForSessionCompletion { try subject.deactivatePlaybackSession(completion: $0) }

        XCTAssertEqual(stubAudioSession.setActiveWasCalledOnMainThread, false)
    }

    // MARK: - requestRecordPermission

    func test_requestRecordPermission_callsAudioSession() {
        subject.requestRecordPermission { _ in }

        XCTAssertNotNil(stubAudioSession.requestRecordPermissionWasCalledWithResponse)
    }

    // MARK: - Helpers

    private func waitForSessionCompletion(
        file: StaticString = #filePath,
        line: UInt = #line,
        _ action: (@escaping @Sendable (Error?) -> Void) throws -> Void
    ) throws -> Error? {
        try waitFor(file: file, line: line) { done in
            do {
                try action(done)
            } catch {
                done(error)
            }
        }
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
    private(set) var setActiveWasCalledOnMainThread: Bool?
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
        setActiveWasCalledOnMainThread = Thread.isMainThread

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
