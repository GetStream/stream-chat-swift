//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Speech
@testable import StreamChatAI
import SwiftUI
import UIKit
import XCTest

@MainActor
final class AIComposerContentView_Tests: XCTestCase {
    @MainActor
    private final class Screen: ObservableObject {
        @Published var showsComposer = true
        @Published var viewModel = AIComposerViewModel()
    }

    // Shows the composer until the test takes it away, as when the person leaves the screen, or
    // gives it another draft, as when the person opens another conversation.
    private struct ScreenView: View {
        @ObservedObject var screen: Screen
        let speechHandler: SpeechHandler

        var body: some View {
            if screen.showsComposer {
                AIComposerContentView(
                    viewFactory: DefaultAIComposerViewFactory.shared,
                    viewModel: screen.viewModel,
                    speechHandler: speechHandler,
                    onMessageSend: { _ in },
                    onStopGenerating: nil
                )
            }
        }
    }

    private let system = SpeechSystemFake()
    private lazy var screen = Screen()

    func test_disappearing_whileTheMicrophoneIsAsked_dictationDoesNotStart() async throws {
        system.microphonePermission = .undetermined
        let handler = SpeechHandler(system: system)
        let window = show(handler)
        try await layOut(window)

        handler.start()
        XCTAssertEqual(system.microphonePermissionRequests.count, 1)
        screen.showsComposer = false
        try await layOut(window)
        system.answerMicrophonePermission(true)

        XCTAssertTrue(system.activations.isEmpty, "the person allowed the microphone after the composer went away")
        XCTAssertFalse(handler.isRecording)
        window.isHidden = true
    }

    func test_disappearing_whileSpeechRecognitionIsAsked_dictationDoesNotStart() async throws {
        system.speechAuthorization = .notDetermined
        system.microphonePermission = .undetermined
        let handler = SpeechHandler(system: system)
        let window = show(handler)
        try await layOut(window)

        handler.start()
        XCTAssertEqual(system.speechAuthorizationRequests.count, 1)
        screen.showsComposer = false
        try await layOut(window)
        system.answerSpeechAuthorization(.authorized)

        XCTAssertTrue(system.microphonePermissionRequests.isEmpty, "the person isn't asked for the microphone")
        XCTAssertTrue(system.activations.isEmpty)
        XCTAssertFalse(handler.isRecording)
        window.isHidden = true
    }

    func test_disappearing_whileTheAudioSessionActivates_dictationDoesNotStart() async throws {
        let handler = SpeechHandler(system: system)
        let window = show(handler)
        try await layOut(window)

        handler.start()
        XCTAssertEqual(system.activations.count, 1)
        screen.showsComposer = false
        try await layOut(window)
        XCTAssertEqual(system.deactivations, 1, "so other apps' audio plays again")
        system.finishActivation()

        XCTAssertFalse(handler.isRecording)
        window.isHidden = true
    }

    func test_switchingDrafts_whileTheMicrophoneIsAsked_dictationDoesNotStart() async throws {
        system.microphonePermission = .undetermined
        let handler = SpeechHandler(system: system)
        let window = show(handler)
        try await layOut(window)

        handler.start()
        XCTAssertEqual(system.microphonePermissionRequests.count, 1)
        screen.viewModel = AIComposerViewModel()
        try await layOut(window)
        system.answerMicrophonePermission(true)

        XCTAssertTrue(system.activations.isEmpty, "what the person says would go in the other draft")
        XCTAssertFalse(handler.isRecording)
        window.isHidden = true
    }

    private func show(_ handler: SpeechHandler) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UIHostingController(
            rootView: ScreenView(screen: screen, speechHandler: handler)
        )
        window.makeKeyAndVisible()
        return window
    }

    private func layOut(_ window: UIWindow) async throws {
        for _ in 0..<3 {
            try await Task.sleep(nanoseconds: 100_000_000)
            window.layoutIfNeeded()
        }
    }
}
