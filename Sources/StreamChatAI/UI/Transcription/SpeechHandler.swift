//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import Speech
import StreamCore

@available(iOS 15.0, macOS 12.0, *)
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
    private let system: any SpeechSystem
    private var speechRecognizer: SFSpeechRecognizer?
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    // When the person last spoke: written from the audio thread, read on the main actor.
    private let lastSpeech = AllocatedUnfairLock(Date.distantPast)
    private var monitorTask: Task<Void, Never>?
    private var interruptionObserver: NSObjectProtocol?
    // Incremented by each start and stop, so what an earlier start still hears back, and what
    // the recognizer reports for an earlier session, is ignored.
    private var sessionGeneration = 0
    // From `start()` until it records or fails: the permission prompts, then the audio session's
    // activation.
    private var isStarting = false
    private var isSessionActive = false

    override public init() {
        system = LiveSpeechSystem()
    }

    init(system: any SpeechSystem) {
        self.system = system
    }

    // MARK: - Authorization

    public func requestAuthorization() {
        system.requestSpeechAuthorization { @Sendable [weak self] status in
            Task { @MainActor in
                self?.authorizationStatus = status
            }
        }
    }

    // MARK: - Recording Control

    /// Starts dictating, once the person allows speech recognition and the microphone.
    public func start() {
        guard !isRecording, !isStarting else { return }
        lastError = nil
        isStarting = true
        sessionGeneration += 1
        authorizeSpeech(for: sessionGeneration)
    }

    /// Stops dictating, or a start that still waits for the person's permissions or for the
    /// audio session. It does nothing when there is neither.
    public func stop() {
        isStarting = false
        // What a start still waits for, and what the recognizer still reports, belong to the
        // session that ended.
        sessionGeneration += 1
        monitorTask?.cancel()
        monitorTask = nil

        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
            interruptionObserver = nil
        }

        // Only a session that started recognizing has an engine to stop, so a stop without one
        // doesn't set up the microphone's input.
        if let request = recognitionRequest {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            request.endAudio()
            recognitionTask?.cancel()

            recognitionTask = nil
            recognitionRequest = nil

            // Fresh engine so the next session never inherits stale AVAudioEngine state.
            audioEngine = AVAudioEngine()
        }

        // Lets other apps' audio, which the session ducked, play at full volume again. While the
        // session is still activating, this runs after it.
        if isSessionActive {
            isSessionActive = false
            system.deactivateAudioSession()
        }

        if isRecording {
            isRecording = false
        }
    }

    // MARK: - Starting

    // Whether the start made at `generation` goes on: no stop or newer start since.
    private func isPendingStart(_ generation: Int) -> Bool {
        isStarting && generation == sessionGeneration
    }

    private func authorizeSpeech(for generation: Int) {
        let status = system.speechAuthorization
        guard status == .notDetermined else {
            speechAuthorized(status, for: generation)
            return
        }
        system.requestSpeechAuthorization { @Sendable [weak self] status in
            Task { @MainActor in
                self?.speechAuthorized(status, for: generation)
            }
        }
    }

    private func speechAuthorized(_ status: SFSpeechRecognizerAuthorizationStatus, for generation: Int) {
        authorizationStatus = status
        guard isPendingStart(generation) else { return }
        guard status == .authorized else {
            failStarting(SpeechHandlerError.speechRecognitionDenied)
            return
        }
        // Asked before recording, so the silence while the person answers doesn't end it.
        switch system.microphonePermission {
        case .undetermined:
            system.requestMicrophonePermission { @Sendable [weak self] granted in
                Task { @MainActor in
                    self?.microphoneAuthorized(granted, for: generation)
                }
            }
        case .denied:
            microphoneAuthorized(false, for: generation)
        case .granted:
            microphoneAuthorized(true, for: generation)
        }
    }

    private func microphoneAuthorized(_ granted: Bool, for generation: Int) {
        guard isPendingStart(generation) else { return }
        guard granted else {
            failStarting(SpeechHandlerError.microphoneDenied)
            return
        }
        guard let recognizer = system.recognizer(for: locale) else {
            failStarting(SpeechHandlerError.recognizerUnavailable)
            return
        }
        speechRecognizer = recognizer
        isSessionActive = true
        system.activateAudioSession { @Sendable [weak self] activation in
            Task { @MainActor in
                self?.finishStarting(generation: generation, activation: activation)
            }
        }
    }

    private func finishStarting(generation: Int, activation: Result<Void, Error>) {
        guard isPendingStart(generation), let recognizer = speechRecognizer else { return }
        isStarting = false
        do {
            try activation.get()
            observeInterruptions()
            let request = startRecognition(using: recognizer)
            try startAudioEngine(feeding: request)
            isRecording = true
            startSilenceMonitor()
        } catch {
            stop()
            lastError = error
        }
    }

    private func failStarting(_ error: Error) {
        isStarting = false
        lastError = error
    }

    // MARK: - Private helpers

    private func observeInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
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
            block: Self.audioTap(feeding: request, lastSpeech: lastSpeech)
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
        lastSpeech.value = Date()

        recognitionTask = recognizer.recognitionTask(
            with: request,
            resultHandler: Self.recognitionHandler(for: self, generation: sessionGeneration, lastSpeech: lastSpeech)
        )
        return request
    }

    private func startSilenceMonitor() {
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                guard !Task.isCancelled, let self else { break }
                let elapsed = Date().timeIntervalSince(self.lastSpeech.value)
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
        lastSpeech: AllocatedUnfairLock<Date>
    ) -> AVAudioNodeTapBlock {
        { buffer, _ in
            request.append(buffer)
            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0, let channelData = buffer.floatChannelData?[0] else { return }
            var sum: Float = 0
            for i in 0..<frameCount { sum += channelData[i] * channelData[i] }
            if sqrt(sum / Float(frameCount)) > 0.01 {
                lastSpeech.value = Date()
            }
        }
    }

    private nonisolated static func recognitionHandler(
        for handler: SpeechHandler,
        generation: Int,
        lastSpeech: AllocatedUnfairLock<Date>
    ) -> (SFSpeechRecognitionResult?, Error?) -> Void {
        { [weak handler] result, error in
            let text = result?.bestTranscription.formattedString ?? ""
            if !text.isEmpty {
                lastSpeech.value = Date()
            }
            Task { @MainActor [handler] in
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
