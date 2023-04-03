//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation

// MARK: - Protocol

public protocol AudioRecording {
    static func build() -> AudioRecording

    var delegate: AudioRecordingDelegate? { get set }

    func beginRecording()

    func pauseRecording()

    func resumeRecording()

    func stopRecording()

    func deleteRecording()
}

// MARK: - Errors

public struct StreamAudioRecorderUnknownError: Error {}
public struct StreamAudioRecorderFailedToInitialize: Error {}
public struct StreamAudioRecorderHasNoRecordPermission: Error {}
public struct StreamAudioRecorderFailedToDeleteRecording: Error {}
public struct StreamAudioRecorderFailedToBeginRecording: Error {}
public struct StreamAudioRecorderFailedToResumeRecording: Error {}
public struct StreamAudioRecorderFailedToSaveRecording: Error {}

// MARK: - Implementation

open class StreamAudioRecorder: NSObject, AudioRecording, AVAudioRecorderDelegate {
    private let audioSessionConfigurator: AudioSessionConfiguring
    private let audioRecorderSettings: [String: Any]
    private let audioRecorderBaseStorageURL: URL
    private let audioRecorderMeterNormaliser: ΑudioRecorderMeterNormalising

    public var recordingURL: URL? { audioRecorder?.url }

    private var audioRecorder: AVAudioRecorder?
    private var updateMetersTimer: Foundation.Timer?
    private var currentTimeObservationToken: Any?
    private var currentTimeTimer: Foundation.Timer?

    open weak var delegate: AudioRecordingDelegate?

    // MARK: - Lifecycle

    public static func build() -> AudioRecording {
        let audioRecorderSettings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        return StreamAudioRecorder(
            audioSessionConfigurator: StreamAudioSessionConfigurator(.sharedInstance()),
            audioRecorderSettings: audioRecorderSettings,
            audioRecorderBaseStorageURL: FileManager.default.temporaryDirectory,
            audioRecorderMeterNormaliser: StreamΑudioRecorderMeterNormaliser()
        )
    }

    public init(
        audioSessionConfigurator: AudioSessionConfiguring,
        audioRecorderSettings: [String: Any],
        audioRecorderBaseStorageURL: URL,
        audioRecorderMeterNormaliser: ΑudioRecorderMeterNormalising
    ) {
        self.audioSessionConfigurator = audioSessionConfigurator
        self.audioRecorderBaseStorageURL = audioRecorderBaseStorageURL
        self.audioRecorderSettings = audioRecorderSettings
        self.audioRecorderMeterNormaliser = audioRecorderMeterNormaliser

        super.init()
    }

    private func makeAudioRecorder() throws -> AVAudioRecorder {
        let audioRecorder = try AVAudioRecorder(
            url: audioRecorderBaseStorageURL.appendingPathComponent("recording.m4a"),
            settings: audioRecorderSettings
        )

        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()

        updateMetersTimer?.invalidate()

        return audioRecorder
    }

    // MARK: - AudioRecording

    open func beginRecording() {
        do {
            try audioSessionConfigurator.activateRecordingSession()

            audioSessionConfigurator.requestRecordPermission { [weak self] in
                self?.handleRecordRequest($0)
            }
        } catch {
            delegate?.audioRecorder(self, didFailOperationWithError: error)
        }
    }

    open func pauseRecording() {
        guard audioRecorder?.isRecording == true else {
            return
        }

        audioRecorder?.pause()
        delegate?.audioRecorderDidPauseRecording(self)
    }

    open func resumeRecording() {
        guard audioRecorder?.isRecording == false else {
            return
        }
        do {
            try audioSessionConfigurator.activateRecordingSession()

            if audioRecorder?.record() == false {
                throw StreamAudioRecorderFailedToResumeRecording()
            } else {
                delegate?.audioRecorderDidResumeRecording(self)
            }
        } catch {
            delegate?.audioRecorder(self, didFailOperationWithError: error)
        }
    }

    open func stopRecording() {
        audioRecorder?.stop()
        updateMetersTimer?.invalidate()
        try? audioSessionConfigurator.deactivateRecordingSession()
        stopObservingCurrentTime()
    }

    open func deleteRecording() {
        guard let audioRecorder = audioRecorder else {
            return
        }

        if audioRecorder.deleteRecording() {
            delegate?.audioRecorderDeletedRecording(self)
        } else {
            delegate?.audioRecorder(self, didFailOperationWithError: StreamAudioRecorderFailedToDeleteRecording())
        }
    }

    // MARK: - AVAudioRecorderDelegate

    open func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder,
        successfully flag: Bool
    ) {
        guard flag else {
            delegate?.audioRecorder(self, didFailOperationWithError: StreamAudioRecorderFailedToSaveRecording())
            return
        }

        let newName = "\(UUID().uuidString).m4a"
        let newLocation = audioRecorderBaseStorageURL
            .appendingPathComponent(newName)
        do {
            let data = try Data(contentsOf: recorder.url.standardizedFileURL)
            try data.write(to: newLocation)
            delegate?.audioRecorderDidFinishRecording(self, url: newLocation)
        } catch {
            delegate?.audioRecorder(self, didFailOperationWithError: error)
        }
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
        delegate?.audioRecorder(self, didFailOperationWithError: error ?? StreamAudioRecorderUnknownError())
    }

    // MARK: - Private Helpers

    private func handleRecordRequest(
        _ permissionGranted: Bool
    ) {
        do {
            guard permissionGranted else { throw StreamAudioRecorderHasNoRecordPermission() }

            audioRecorder = try makeAudioRecorder()

            if audioRecorder?.record() == true {
                startObservingCurrentTime()
                updateMetersTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in self?.didUpdateMeters() })
                delegate?.audioRecorderDidBeginRecording(self)
            } else {
                throw StreamAudioRecorderFailedToBeginRecording()
            }
        } catch {
            delegate?.audioRecorder(self, didFailOperationWithError: error)
        }
    }

    private func didUpdateMeters() {
        guard let audioRecorder = audioRecorder, let delegate = delegate else {
            return
        }
        audioRecorder.updateMeters()

        delegate.audioRecorderDidUpdateMeters(
            self,
            averagePower: audioRecorderMeterNormaliser.normalise(audioRecorder.averagePower(forChannel: 0)),
            peakPower: audioRecorderMeterNormaliser.normalise(audioRecorder.peakPower(forChannel: 0))
        )
    }

    private func startObservingCurrentTime() {
        guard let audioRecorder = audioRecorder else {
            return
        }
        currentTimeTimer?.invalidate()

        currentTimeTimer = Foundation.Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true,
            block: { [weak audioRecorder, weak self] _ in
                guard let audioRecorder = audioRecorder, audioRecorder.isRecording else {
                    return
                }
                self.map { unwrappedSelf in
                    unwrappedSelf.delegate?.audioRecorderDidUpdate(
                        unwrappedSelf,
                        currentTime: audioRecorder.currentTime
                    )
                }
            }
        )
    }

    private func stopObservingCurrentTime() {
        currentTimeTimer?.invalidate()
        currentTimeTimer = nil
    }
}
