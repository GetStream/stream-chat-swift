//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - Protocol

public protocol AudioRecording {
    static func build() -> AudioRecording

    var delegate: AudioRecordingDelegate? { get set }

    var storageURL: URL { get }

    func beginRecording()

    func pauseRecording()

    func resumeRecording()

    func stopRecording()

    func deleteRecording()
}

// MARK: - Errors

public struct StreamAudioRecorderFailedToInitialize: Error {}
public struct StreamAudioRecorderHasNoRecordPermission: Error {}
public struct StreamAudioRecorderFailedToDeleteRecording: Error {}
public struct StreamAudioRecorderFailedToBeginRecording: Error {}

// MARK: - Implementation

open class StreamAudioRecorder: NSObject, AudioRecording, AVAudioRecorderDelegate {
    private let audioSessionConfigurator: AudioSessionConfiguring
    private let audioRecorder: AVAudioRecorder
    private var currentTimeObservationToken: Any?
    private var currentTimeTimer: Foundation.Timer?

    open weak var delegate: AudioRecordingDelegate?

    // MARK: - Lifecycle

    public static func build() -> AudioRecording {
        let commonFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 22050,
            channels: 1,
            interleaved: true
        )!

        let storageDirectory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("recording.m4a")

        // TODO: Change optionality and error throwing
        let result = try? StreamAudioRecorder(
            audioSessionConfigurator: StreamAudioSessionConfigurator(.sharedInstance()),
            audioFormat: commonFormat,
            storageDirectory: storageDirectory
        )
        return result!
    }

    open var storageURL: URL { audioRecorder.url }

    public init(
        audioSessionConfigurator: AudioSessionConfiguring,
        audioFormat: AVAudioFormat,
        storageDirectory: URL
    ) throws {
        self.audioSessionConfigurator = audioSessionConfigurator
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try .init(url: storageDirectory, settings: settings)
        super.init()
        setUp()
    }

    // MARK: - AudioRecording

    open func beginRecording() {
        audioSessionConfigurator.requestRecordPermission { [weak self] allowed in
            guard let self = self else { return }

            guard allowed else {
                self.delegate?.audioRecorder(self, didFailRecording: StreamAudioRecorderHasNoRecordPermission())
                return
            }

            do {
                try self.audioSessionConfigurator.activateRecordingSession(
                    mode: .spokenAudio,
                    policy: .default,
                    preferredInput: .builtInMic
                )

                if self.audioRecorder.record() {
                    self.startObservingCurrentTime()
                    self.delegate?.audioRecorderDidBeginRecording(self)
                } else {
                    throw StreamAudioRecorderFailedToBeginRecording()
                }
            } catch {
                self.delegate?.audioRecorder(self, didFailRecording: error)
            }
        }
    }

    open func pauseRecording() {
        guard audioRecorder.isRecording else {
            return
        }

        audioRecorder.pause()
        try? audioSessionConfigurator.deactivateRecordingSession()
        delegate?.audioRecorderDidPauseRecording(self)
    }

    open func resumeRecording() {
        guard audioRecorder.isRecording == false else {
            return
        }
        try? audioSessionConfigurator.activateRecordingSession(
            mode: .default,
            policy: .default,
            preferredInput: .builtInMic
        )
        audioRecorder.record()
        delegate?.audioRecorderDidResumeRecording(self)
    }

    open func stopRecording() {
        audioRecorder.stop()
        try? audioSessionConfigurator.deactivateRecordingSession()
        stopObservingCurrentTime()
    }

    open func deleteRecording() {
        delegate?.audioRecorderDeletedRecording(
            self,
            error: audioRecorder.deleteRecording() ? nil : StreamAudioRecorderFailedToDeleteRecording()
        )
    }

    // MARK: - AVAudioRecorderDelegate

    open func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder,
        successfully flag: Bool
    ) {
        delegate?.audioRecorderDidFinishRecording(
            self,
            url: flag ? recorder.url : nil
        )
    }

    open func audioRecorderBeginInterruption(
        _ recorder: AVAudioRecorder
    ) {
        delegate?.audioRecorderBeginInterruption(self)
    }

    open func audioRecorderEndInterruption(
        _ recorder: AVAudioRecorder,
        withOptions flags: Int
    ) {
        delegate?.audioRecorderEndInterruption(self)
    }

    open func audioRecorderEncodeErrorDidOccur(
        _ recorder: AVAudioRecorder,
        error: Error?
    ) {
        delegate?.audioRecorderEncodingFailed(self, error: error)
    }

    // MARK: - Private Helpers

    private func setUp() {
        audioRecorder.delegate = self

        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
    }

    private func startObservingCurrentTime() {
        currentTimeTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] _ in
            guard let self = self, self.audioRecorder.isRecording else { return }
            self.delegate?.audioRecorderDidUpdate(self, currentTime: self.audioRecorder.currentTime)
        })
    }

    private func stopObservingCurrentTime() {
        currentTimeTimer?.invalidate()
        currentTimeTimer = nil
    }
}
