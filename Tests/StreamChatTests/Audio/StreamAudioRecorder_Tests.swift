//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StreamAudioRecorder_Tests: XCTestCase {
    private var avAudioRecorderFactoryWasCalledWithURL: URL?
    private var avAudioRecorderFactoryWasCalledWithSettings: [String: Any]?

    private lazy var avAudioRecorderFactoryResult: Result<StubAudioRecorder, Error>! = .success(stubAVAudioRecorder)
    private lazy var audioSessionConfigurator: MockAudioSessionConfigurator! = .init()
    private lazy var audioRecorderMeterNormaliser: MockΑudioRecorderMeterNormaliser! = .init()
    private lazy var mockRecorderDelegate: MockAudioRecordingDelegate! = .init()
    private lazy var appstateObserver: MockAppStateObserver! = .init()
    private lazy var stubAVAudioRecorder: StubAudioRecorder! = .init()
    private lazy var genericError: Error! = NSError(domain: "test", code: 10)

    private var subject: StreamAudioRecorder!

    override func tearDown() {
        try? FileManager.default.removeItem(at: stubAVAudioRecorder.url)
        avAudioRecorderFactoryWasCalledWithURL = nil
        avAudioRecorderFactoryWasCalledWithSettings = nil
        avAudioRecorderFactoryResult = nil
        audioSessionConfigurator = nil
        audioRecorderMeterNormaliser = nil
        mockRecorderDelegate = nil
        stubAVAudioRecorder = nil
        appstateObserver = nil
        genericError = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - configureAudioSessionConfigurator

    func test_configureAudioSessionConfigurator_onlyNewInstanceIsInvoked() {
        setAudioRecorder()
        let newAudioSessionConfigurator = MockAudioSessionConfigurator()
        subject.configure(newAudioSessionConfigurator)

        subject.beginRecording {}

        XCTAssertEqual(newAudioSessionConfigurator.recordedFunctions, [
            "activateRecordingSession()",
            "requestRecordPermission(_:)"
        ])
        XCTAssertTrue(audioSessionConfigurator.recordedFunctions.isEmpty)
    }

    // MARK: - beginRecording

    func test_beginRecording_audioSessionConfiguratorThrowsAnError_callsDidFailWithErrorOnDelegate() throws {
        audioSessionConfigurator.activateRecordingSessionThrowsError = genericError
        setAudioRecorder()
        let completionHandlerExpectation = expectation(description: "Completion handler was called.")
        completionHandlerExpectation.isInverted = true

        subject?.beginRecording { completionHandlerExpectation.fulfill() }

        wait(for: [completionHandlerExpectation], timeout: defaultTimeout)
        assertDidFailWithError(genericError)
    }

    func test_beginRecording_audioSessionConfiguratorRequestRecordPersmissionReturnsFalse_callsDidFailWithErrorOnDelegate() throws {
        setAudioRecorder()
        let completionHandlerExpectation = expectation(description: "Completion handler was called.")
        completionHandlerExpectation.isInverted = true
        stubAVAudioRecorder.stubProperty(\.isRecording, with: false)
        stubAVAudioRecorder.stubProperty(\.currentTime, with: 10)

        subject?.beginRecording { completionHandlerExpectation.fulfill() }
        audioSessionConfigurator.requestRecordPermissionCompletionHandler?(false)

        wait(for: [completionHandlerExpectation], timeout: defaultTimeout)
        assertDidFailWithClientError(AudioRecorderError.noRecordPermission())
    }

    func test_beginRecording_failedToInitialiseAVAudioRecorder_callsDidFailWithErrorOnDelegate() throws {
        avAudioRecorderFactoryResult = .failure(genericError)
        setAudioRecorder()
        let completionHandlerExpectation = expectation(description: "Completion handler was called.")
        completionHandlerExpectation.isInverted = true

        subject?.beginRecording { completionHandlerExpectation.fulfill() }
        audioSessionConfigurator.requestRecordPermissionCompletionHandler?(true)

        wait(for: [completionHandlerExpectation], timeout: defaultTimeout)
        assertDidFailWithError(genericError)
    }

    func test_beginRecording_avAudioRecorderWasCreated_avAudioRecorderWasConfiguredCorrectly() throws {
        setAudioRecorder()
        let completionHandlerExpectation = expectation(description: "Completion handler was called.")
        completionHandlerExpectation.isInverted = true

        subject?.beginRecording { completionHandlerExpectation.fulfill() }
        audioSessionConfigurator.requestRecordPermissionCompletionHandler?(true)

        wait(for: [completionHandlerExpectation], timeout: defaultTimeout)
        XCTAssertEqual(avAudioRecorderFactoryWasCalledWithURL, FileManager.default.temporaryDirectory.appendingPathComponent("recording.aac"))
        XCTAssertEqual(avAudioRecorderFactoryWasCalledWithSettings?[AVFormatIDKey] as? Int, Int(kAudioFormatMPEG4AAC))
        XCTAssertEqual(avAudioRecorderFactoryWasCalledWithSettings?[AVSampleRateKey] as? Int, 12000)
        XCTAssertEqual(avAudioRecorderFactoryWasCalledWithSettings?[AVNumberOfChannelsKey] as? Int, 1)
        XCTAssertEqual(avAudioRecorderFactoryWasCalledWithSettings?[AVEncoderAudioQualityKey] as? Int, AVAudioQuality.high.rawValue)
        XCTAssertTrue(stubAVAudioRecorder.delegate === subject)
        XCTAssertTrue(stubAVAudioRecorder.isMeteringEnabled)
        XCTAssertTrue(stubAVAudioRecorder.prepareToRecordWasCalled)
    }

    func test_beginRecording_failedToBeginRecording_callsDidFailWithErrorOnDelegate() throws {
        stubAVAudioRecorder.recordResult = false
        setAudioRecorder()
        let completionHandlerExpectation = expectation(description: "Completion handler was called.")
        completionHandlerExpectation.isInverted = true

        subject?.beginRecording { completionHandlerExpectation.fulfill() }
        audioSessionConfigurator.requestRecordPermissionCompletionHandler?(true)

        wait(for: [completionHandlerExpectation], timeout: defaultTimeout)
        assertDidFailWithClientError(AudioRecorderError.failedToBegin())
    }

    func test_beginRecording_beginsRecording_callsDidUpdateContextOnDelegate() throws {
        simulateIsRecording()
    }

    func test_beginRecording_beginsRecording_durationObserverHasBeenSetUpCorrectly() throws {
        simulateIsRecording()
        stubAVAudioRecorder.stubProperty(\.currentTime, with: 10)

        let waitObserversExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            self.mockRecorderDelegate.didUpdateContextWasCalledWithContext?.duration == 10
        }), object: nil)

        wait(for: [waitObserversExpectation], timeout: 2)
    }

    func test_beginRecording_beginsRecording_metersObserverHasBeenSetUpCorrectly() throws {
        simulateIsRecording()
        stubAVAudioRecorder.averagePowerResult = 100
        stubAVAudioRecorder.stubProperty(\.currentTime, with: 10)

        let waitObserversExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            self.stubAVAudioRecorder.updateMetersWasCalled == true
                && self.stubAVAudioRecorder.averagePowerWasCalledWithChannelNumber == 0
                && self.audioRecorderMeterNormaliser.normaliseWasCalledWithValue == 100
        }), object: nil)

        wait(for: [waitObserversExpectation], timeout: 2)
    }

    // MARK: - pauseRecording

    func test_pauseRecording_audioRecorderIsRecording_callsPauseOnPlayerAndUpdatesDelegate() {
        simulateIsRecording()

        subject.pauseRecording()

        XCTAssertTrue(stubAVAudioRecorder.pauseWasCalled)
        assertContextUpdate(.init(state: .paused, duration: 0, averagePower: 0))
    }

    func test_pauseRecording_audioRecorderIsNotRecording_doesNotCallPauseOnPlayer() {
        simulateIsRecording()
        stubAVAudioRecorder.stubProperty(\.isRecording, with: false)

        subject.pauseRecording()

        XCTAssertFalse(stubAVAudioRecorder.pauseWasCalled)
    }

    // MARK: - resumeRecording

    func test_resumeRecording_audioRecorderIsRecording_doesNotDoAnything() {
        simulateIsRecording()
        audioSessionConfigurator.recordedFunctions = []
        stubAVAudioRecorder.recordWasCalled = false

        subject.resumeRecording()

        XCTAssertTrue(audioSessionConfigurator.recordedFunctions.isEmpty)
        XCTAssertFalse(stubAVAudioRecorder.recordWasCalled)
    }

    func test_resumeRecording_audioRecorderIsNotRecording_callsActivateRecordingSessionWhichFails_callsDidFailOnDelegate() {
        simulateIsRecording()
        subject.pauseRecording()
        audioSessionConfigurator.recordedFunctions = []
        stubAVAudioRecorder.recordWasCalled = false
        stubAVAudioRecorder.stubProperty(\.isRecording, with: false)
        audioSessionConfigurator.activateRecordingSessionThrowsError = genericError

        subject.resumeRecording()

        assertDidFailWithError(genericError)
        XCTAssertFalse(stubAVAudioRecorder.recordWasCalled)
    }

    func test_resumeRecording_audioRecorderIsNotRecording_failsToStartRecording_callsDidFailOnDelegate() {
        simulateIsRecording()
        subject.pauseRecording()
        audioSessionConfigurator.recordedFunctions = []
        stubAVAudioRecorder.recordWasCalled = false
        stubAVAudioRecorder.stubProperty(\.isRecording, with: false)
        stubAVAudioRecorder.recordResult = false

        subject.resumeRecording()

        assertDidFailWithClientError(AudioRecorderError.failedToResume())
    }

    func test_resumeRecording_audioRecorderIsNotRecording_resumesRecordingSuccessfully_callsDidUpdateContextOnDelegate() {
        simulateIsRecording()
        subject.pauseRecording()
        stubAVAudioRecorder.stubProperty(\.isRecording, with: false)
        stubAVAudioRecorder.recordResult = true
        assertContextUpdate(.init(state: .paused, duration: 0, averagePower: 0))

        subject.resumeRecording()

        assertContextUpdate(.init(state: .recording, duration: 0, averagePower: 0))
    }

    // MARK: - stopRecording

    func test_stopRecording_audioRecorderIsRecording_callsStopOnPlayer() {
        simulateIsRecording()

        subject.stopRecording()

        XCTAssertTrue(stubAVAudioRecorder.stopWasCalled)
    }

    func test_stopRecording_audioRecorderIsRecording_stopsDurationObserver() {
        simulateIsRecording()

        subject.stopRecording()
        stubAVAudioRecorder.stubProperty(\.currentTime, with: 23)

        let waitObserversExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            self.mockRecorderDelegate.didUpdateContextWasCalledWithContext?.duration == 23
        }), object: nil)
        waitObserversExpectation.isInverted = true

        wait(for: [waitObserversExpectation], timeout: 2)
    }

    func test_stopRecording_audioRecorderIsRecording_stopsMetersObserver() {
        simulateIsRecording()

        subject.stopRecording()
        stubAVAudioRecorder.averagePowerResult = 19

        let waitObserversExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(block: { _, _ in
            self.mockRecorderDelegate.didUpdateContextWasCalledWithContext?.averagePower == 19
        }), object: nil)
        waitObserversExpectation.isInverted = true

        wait(for: [waitObserversExpectation], timeout: 2)
    }

    func test_stopRecording_audioRecorderIsRecording_failsToDeactiveRecordingSession_callsDidFailOnDelegate() {
        simulateIsRecording()
        audioSessionConfigurator.deactivateRecordingSessionThrowsError = genericError

        subject.stopRecording()

        assertDidFailWithError(genericError)
    }

    // MARK: - audioRecorderDidFinishRecording(_:successfully:)

    func test_audioRecorderDidFinishRecording_flagIsFalse_callsDidFailOnDelegate() {
        simulateIsRecording()

        subject.audioRecorderDidFinishRecording(stubAVAudioRecorder, successfully: false)

        assertDidFailWithClientError(AudioRecorderError.failedToSave())
    }

    func test_audioRecorderDidFinishRecording_flagIsTrue_newLocationIsInvalidAndWriteFails_callsDidFailOnDelegate() {
        var configuration = StreamAudioRecorder.Configuration.default
        configuration.audioRecorderBaseStorageURL = .unique()
        setAudioRecorder(configuration)
        simulateIsRecording()

        subject.audioRecorderDidFinishRecording(stubAVAudioRecorder, successfully: true)

        XCTAssertTrue(
            (mockRecorderDelegate.didFailWithErrorWasCalledWithAudioRecorder as? StreamAudioRecorder) === subject
        )
        XCTAssertNotNil(mockRecorderDelegate.didFailWithErrorWasCalledWithError)
    }

    func test_audioRecorderDidFinishRecording_flagIsTrue_writeCompletesSuccesfully_callsDidFinishRecordingAtURLOnDelegate() {
        simulateIsRecording()

        subject.audioRecorderDidFinishRecording(stubAVAudioRecorder, successfully: true)

        XCTAssertTrue(
            (mockRecorderDelegate.didFinishRecordingAtURLWasCalledWithAudioRecorder as? StreamAudioRecorder) === subject
        )
        XCTAssertNotNil(mockRecorderDelegate.didFinishRecordingAtURLWasCalledWithURL)
    }

    // MARK: - audioRecorderBeginInterruption(_:)

    func test_audioRecorderBeginInterruption_stoppedWasCalledOnRecorder() {
        simulateIsRecording()

        subject.audioRecorderBeginInterruption(stubAVAudioRecorder)

        XCTAssertTrue(stubAVAudioRecorder.stopWasCalled)
    }

    // MARK: - audioRecorderEndInterruption(_:withOptions:)

    /* No-op */

    // MARK: - audioRecorderEncodeErrorDidOccur(_:error:)

    func test_audioRecorderEncodeErrorDidOccur_withError_callsDidFailOnDelegate() {
        simulateIsRecording()

        subject.audioRecorderEncodeErrorDidOccur(stubAVAudioRecorder, error: genericError)

        assertDidFailWithError(genericError)
    }

    func test_audioRecorderEncodeErrorDidOccur_withoutError_callsDidFailOnDelegate() {
        simulateIsRecording()

        subject.audioRecorderEncodeErrorDidOccur(stubAVAudioRecorder, error: nil)

        assertDidFailWithClientError(AudioRecorderError.unknown())
    }

    func test_audioRecorderEncodeErrorDidOccur_stoppedWasCalledOnRecorder() {
        simulateIsRecording()

        subject.audioRecorderEncodeErrorDidOccur(stubAVAudioRecorder, error: nil)

        XCTAssertTrue(stubAVAudioRecorder.stopWasCalled)
    }

    // MARK: - Private Helpers

    private func setAudioRecorder(
        _ configuration: StreamAudioRecorder.Configuration = .default,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        subject = .init(
            configuration: configuration,
            audioSessionConfigurator: audioSessionConfigurator,
            audioRecorderMeterNormaliser: audioRecorderMeterNormaliser,
            appStateObserver: appstateObserver,
            audioRecorderAVProvider: {
                self.avAudioRecorderFactoryWasCalledWithURL = $0
                self.avAudioRecorderFactoryWasCalledWithSettings = $1
                switch self.avAudioRecorderFactoryResult {
                case let .success(result):
                    return result
                case let .failure(error):
                    throw error
                case .none:
                    XCTFail(file: file, line: line)
                    return StubAudioRecorder()
                }
            }
        )

        subject.subscribe(mockRecorderDelegate)
    }

    private func simulateIsRecording(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let completionHandlerExpectation = expectation(description: "Completion handler was called.")

        stubAVAudioRecorder.recordResult = true
        if subject == nil {
            setAudioRecorder()
        }

        stubAVAudioRecorder.stubProperty(\.currentTime, with: 10)
        subject?.beginRecording { completionHandlerExpectation.fulfill() }
        audioSessionConfigurator.requestRecordPermissionCompletionHandler?(true)
        assertContextUpdate(.init(state: .recording, duration: 0, averagePower: 0), file: file, line: line)
        stubAVAudioRecorder.stubProperty(\.isRecording, with: true)
        wait(for: [completionHandlerExpectation], timeout: defaultTimeout)
    }

    private func assertContextUpdate(
        _ expectedContext: @autoclosure () -> AudioRecordingContext,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue((mockRecorderDelegate.didUpdateContextWasCalledWithAudioRecorder as? StreamAudioRecorder) === subject)
        XCTAssertEqual(
            mockRecorderDelegate.didUpdateContextWasCalledWithContext,
            expectedContext(),
            file: file,
            line: line
        )
    }

    private func assertDidFailWithClientError(
        _ expectedError: @autoclosure () -> ClientError,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            (mockRecorderDelegate.didFailWithErrorWasCalledWithAudioRecorder as? StreamAudioRecorder) === subject,
            file: file,
            line: line
        )
        XCTAssertEqual(
            (mockRecorderDelegate.didFailWithErrorWasCalledWithError as? ClientError)?.message,
            expectedError().message,
            file: file,
            line: line
        )
    }

    private func assertDidFailWithError(
        _ expectedError: @autoclosure () -> Error,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            (mockRecorderDelegate.didFailWithErrorWasCalledWithAudioRecorder as? StreamAudioRecorder) === subject,
            file: file,
            line: line
        )
        XCTAssertEqual(
            mockRecorderDelegate.didFailWithErrorWasCalledWithError,
            expectedError(),
            file: file,
            line: line
        )
    }
}

private final class MockΑudioRecorderMeterNormaliser: AudioValuePercentageNormaliser {
    private(set) var normaliseWasCalledWithValue: Float?
    var normaliseResult: Float = 0

    override func normalise(_ value: Float) -> Float {
        normaliseWasCalledWithValue = value
        return normaliseResult
    }
}

@dynamicMemberLookup
private final class StubAudioRecorder: AVAudioRecorder, Stub {
    var stubbedProperties: [String: Any] = [:]

    var recordWasCalled = false
    var recordResult: Bool = false

    var prepareToRecordWasCalled = false
    var prepareToRecordResult: Bool = false

    var averagePowerWasCalledWithChannelNumber: Int?
    var averagePowerResult: Float = 0

    var updateMetersWasCalled: Bool = false

    var pauseWasCalled: Bool = false

    var stopWasCalled: Bool = false

    var deleteRecordingWasCalled: Bool = false
    var deleteRecordingResult: Bool = false

    override var currentTime: TimeInterval { self[dynamicMember: \.currentTime] }
    override var isRecording: Bool { self[dynamicMember: \.isRecording] }

    override convenience init() {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("test_recording.aac")
        try! self.init(
            url: path,
            format: .init(settings: [AVFormatIDKey: kAudioFormatMPEG4AAC])!
        )

        try! "test-content".data(using: .utf8)!.write(to: path.standardizedFileURL)
    }

    override func record() -> Bool {
        recordWasCalled = true
        return recordResult
    }

    override func prepareToRecord() -> Bool {
        prepareToRecordWasCalled = true
        return prepareToRecordResult
    }

    override func averagePower(forChannel channelNumber: Int) -> Float {
        averagePowerWasCalledWithChannelNumber = channelNumber
        return averagePowerResult
    }

    override func updateMeters() {
        updateMetersWasCalled = true
    }

    override func pause() {
        pauseWasCalled = true
    }

    override func stop() {
        stopWasCalled = true
    }

    override func deleteRecording() -> Bool {
        deleteRecordingWasCalled = true
        return deleteRecordingResult
    }
}
