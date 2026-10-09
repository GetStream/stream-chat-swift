//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import Speech
import StreamCore

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
    // When the person last spoke: written from the audio thread, read on the main actor.
    private let lastSpeech = AllocatedUnfairLock(Date.distantPast)
    private var monitorTask: Task<Void, Never>?
    private var interruptionObserver: NSObjectProtocol?
    // Incremented each session so callbacks from the previous session are ignored.
    private var sessionGeneration = 0
    private var isStarting = false
    private var isSessionActive = false
    // Activating and deactivating the audio session can block for a while, so both run here,
    // in order, off the main thread.
    private nonisolated static let audioSessionQueue = DispatchQueue(label: "io.getstream.ai.speech-audio-session")

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
        guard !isRecording, !isStarting else { return }
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

        isStarting = true
        isSessionActive = true
        sessionGeneration += 1
        let generation = sessionGeneration
        Self.audioSessionQueue.async { [weak self] in
            let activation = Result { try Self.activateAudioSession() }
            Task { @MainActor in
                self?.finishStarting(generation: generation, activation: activation)
            }
        }
    }

    private func finishStarting(generation: Int, activation: Result<Void, Error>) {
        // A stop, or a newer start, since this one began.
        guard isStarting, generation == sessionGeneration, let recognizer = speechRecognizer else { return }
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

    public func stop() {
        isStarting = false
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

        // Lets other apps' audio, which the session ducked, play at full volume again.
        if isSessionActive {
            isSessionActive = false
            Self.audioSessionQueue.async {
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }
        }

        isRecording = false
    }

    // MARK: - Private helpers

    private nonisolated static func activateAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

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
