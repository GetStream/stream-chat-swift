//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public final class MockAudioRecordingDelegate: AudioRecordingDelegate {

    public private(set) var didUpdateContextWasCalledWithAudioRecorder: AudioRecording?
    public private(set) var didUpdateContextWasCalledWithContext: AudioRecordingContext?

    public private(set) var didFinishRecordingAtURLWasCalledWithAudioRecorder: AudioRecording?
    public private(set) var didFinishRecordingAtURLWasCalledWithURL: URL?

    public private(set) var didFailWithErrorWasCalledWithAudioRecorder: AudioRecording?
    public private(set) var didFailWithErrorWasCalledWithError: Error?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - AudioRecordingDelegate

    public func audioRecorder(
        _ audioRecorder: AudioRecording,
        didUpdateContext context: AudioRecordingContext
    ) {
        didUpdateContextWasCalledWithAudioRecorder = audioRecorder
        didUpdateContextWasCalledWithContext = context
    }

    public func audioRecorder(
        _ audioRecorder: AudioRecording,
        didFinishRecordingAtURL location: URL
    ) {
        didFinishRecordingAtURLWasCalledWithAudioRecorder = audioRecorder
        didFinishRecordingAtURLWasCalledWithURL = location
    }

    public func audioRecorder(
        _ audioRecorder: AudioRecording,
        didFailWithError error: Error
    ) {
        didFailWithErrorWasCalledWithAudioRecorder = audioRecorder
        didFailWithErrorWasCalledWithError = error
    }
}
