//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public final class MockAudioRecorder: AudioRecording {

    public private(set) var subscribeWasCalledWithSubscriber: AudioRecordingDelegate?
    public private(set) var beginRecordingWasCalledWithCompletionHandler: (() -> Void)?
    public private(set) var pauseRecordingWasCalled: Bool = false
    public private(set) var resumeRecordingWasCalled: Bool = false
    public private(set) var stopRecordingWasCalled: Bool = false

    public required init() {}

    public func subscribe(_ subscriber: AudioRecordingDelegate) {
        subscribeWasCalledWithSubscriber = subscriber
    }

    public func beginRecording(_ completionHandler: @escaping (() -> Void)) {
        beginRecordingWasCalledWithCompletionHandler = completionHandler
    }

    public func pauseRecording() {
        pauseRecordingWasCalled = true
    }

    public func resumeRecording() {
        resumeRecordingWasCalled = true
    }

    public func stopRecording() {
        stopRecordingWasCalled = true
    }
}
