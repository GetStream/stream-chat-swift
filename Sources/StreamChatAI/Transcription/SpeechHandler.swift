//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
public final class SpeechHandler: NSObject, ObservableObject {
    // Public state for SwiftUI
    @Published private(set) var isRecording = false
    @Published var transcript: String = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var lastError: Error?

    // Configuration
    var locale: Locale = Locale(identifier: "en-US")
    var silenceTimeout: TimeInterval = 3.0

    // Internals
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechActivity = SpeechActivity()
    private var monitorTask: Task<Void, Never>?
    private var interruptionObserver: NSObjectProtocol?
    // Incremented each session so callbacks from the previous session are ignored.
    private var sessionGeneration = 0

    override public init() {
        // Public init.
    }

    // MARK: - Authorization

    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { @Sendable [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
            }
        }
    }

    // MARK: - Recording Control

    public func start() {
        guard !isRecording else { return }
        lastError = nil

        let currentStatus = SFSpeechRecognizer.authorizationStatus()
        if currentStatus == .notDetermined {
            SFSpeechRecognizer.requestAuthorization { @Sendable [weak self] status in
                Task { @MainActor in
                    self?.authorizationStatus = status
                    if status == .authorized { self?.start() }
                }
            }
            return
        }
        authorizationStatus = currentStatus

        speechRecognizer = SFSpeechRecognizer(locale: locale)
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            lastError = SpeechHandlerError.recognizerUnavailable
            return
        }

        do {
            try configureAudioSession()
            let request = startRecognition(using: recognizer)
            try startAudioEngine(feeding: request)
            isRecording = true
            startSilenceMonitor()
        } catch {
            stop()
            lastError = error
        }
    }

    public func stop() {
        monitorTask?.cancel()
        monitorTask = nil

        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionTask = nil
        recognitionRequest = nil

        // Fresh engine so the next session never inherits stale AVAudioEngine state.
        audioEngine = AVAudioEngine()

        isRecording = false
    }

    // MARK: - Private helpers

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { @Sendable [weak self] note in
            guard
                let typeValue = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                AVAudioSession.InterruptionType(rawValue: typeValue) == .began
            else { return }
            MainActor.assumeIsolated {
                self?.stop()
            }
        }
    }

    private func startAudioEngine(feeding request: SFSpeechAudioBufferRecognitionRequest) throws {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format,
            block: Self.audioTap(feeding: request, activity: speechActivity)
        )

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func startRecognition(using recognizer: SFSpeechRecognizer) -> SFSpeechAudioBufferRecognitionRequest {
        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        transcript = ""
        speechActivity.markSpeech()

        sessionGeneration += 1
        recognitionTask = recognizer.recognitionTask(
            with: request,
            resultHandler: Self.recognitionHandler(for: self, generation: sessionGeneration, activity: speechActivity)
        )
        return request
    }

    private func startSilenceMonitor() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                guard !Task.isCancelled, let self else { break }
                let elapsed = Date().timeIntervalSince(self.speechActivity.lastSpeechTime)
                if elapsed >= self.silenceTimeout {
                    self.stop()
                    break
                }
            }
        }
    }

    // The audio tap and the recognition handler run on background threads, so they are made
    // outside the main actor and only reach it through a task.

    private nonisolated static func audioTap(
        feeding request: SFSpeechAudioBufferRecognitionRequest,
        activity: SpeechActivity
    ) -> AVAudioNodeTapBlock {
        { buffer, _ in
            request.append(buffer)
            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0, let channelData = buffer.floatChannelData?[0] else { return }
            var sum: Float = 0
            for i in 0..<frameCount { sum += channelData[i] * channelData[i] }
            if sqrt(sum / Float(frameCount)) > 0.01 {
                activity.markSpeech()
            }
        }
    }

    private nonisolated static func recognitionHandler(
        for handler: SpeechHandler,
        generation: Int,
        activity: SpeechActivity
    ) -> (SFSpeechRecognitionResult?, Error?) -> Void {
        { [weak handler] result, error in
            let text = result?.bestTranscription.formattedString ?? ""
            if !text.isEmpty {
                activity.markSpeech()
            }
            Task { @MainActor in
                guard let handler, handler.sessionGeneration == generation else { return }
                if !text.isEmpty {
                    handler.transcript = text
                }
                if let error {
                    handler.lastError = error
                }
            }
        }
    }
}

/// When the person last spoke: written from the audio thread, read on the main actor.
private final class SpeechActivity: @unchecked Sendable {
    private let lock = NSLock()
    private var lastSpeech = Date.distantPast

    var lastSpeechTime: Date {
        lock.lock()
        defer { lock.unlock() }
        return lastSpeech
    }

    func markSpeech() {
        lock.lock()
        lastSpeech = Date()
        lock.unlock()
    }
}

// MARK: - Errors

enum SpeechHandlerError: LocalizedError {
    case recognizerUnavailable
    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return L10n.Transcription.recognizerUnavailable
        }
    }
}
