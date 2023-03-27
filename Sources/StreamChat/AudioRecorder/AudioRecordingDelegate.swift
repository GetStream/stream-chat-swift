//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol AudioRecordingDelegate: AnyObject {
    func audioRecorderDidBeginRecording(_ audioRecorder: AudioRecording)
    func audioRecorder(_ audioRecorder: AudioRecording, didFailRecording: Error)

    func audioRecorderDidPauseRecording(_ audioRecorder: AudioRecording)
    func audioRecorderDidResumeRecording(_ audioRecorder: AudioRecording)
    func audioRecorderDidFinishRecording(_ audioRecorder: AudioRecording, url: URL?)

    func audioRecorderDidUpdate(_ audioRecorder: AudioRecording, currentTime: TimeInterval)

    func audioRecorderDeletedRecording(_ audioRecorder: AudioRecording, error: Error?)

    func audioRecorderBeginInterruption(_ audioRecorder: AudioRecording)
    func audioRecorderEndInterruption(_ audioRecorder: AudioRecording)

    func audioRecorderEncodingFailed(_ audioRecorder: AudioRecording, error: Error?)
}
