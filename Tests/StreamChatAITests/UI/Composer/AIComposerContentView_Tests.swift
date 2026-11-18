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
    private final class Screen: ObservableObject {
        @Published var showsComposer = true
    }

    // Shows the composer until the test takes it away, as when the person leaves the screen.
    private struct ScreenView: View {
        @ObservedObject var screen: Screen
        let viewModel: AIComposerViewModel
        let speechHandler: SpeechHandler

        var body: some View {
            if screen.showsComposer {
                AIComposerContentView(
                    viewFactory: DefaultAIComposerViewFactory.shared,
                    viewModel: viewModel,
                    speechHandler: speechHandler,
                    onMessageSend: { _ in },
                    onStopGenerating: nil
                )
            }
        }
    }

    private let system = SpeechSystemFake()
    private let screen = Screen()

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
        await settle()

        XCTAssertTrue(system.activations.isEmpty, "the person allowed the microphone after the composer went away")
        XCTAssertFalse(handler.isRecording)
        window.isHidden = true
    }

    func test_disappearing_whileSpeechRecognitionIsAsked_dictationDoesNotStart() async throws {
        system.speechAuthorization = .notDetermined
        let handler = SpeechHandler(system: system)
        let window = show(handler)
        try await layOut(window)

        handler.start()
        XCTAssertEqual(system.speechAuthorizationRequests.count, 1)
        screen.showsComposer = false
        try await layOut(window)
        system.answerSpeechAuthorization(.authorized)
        await settle()

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
        XCTAssertEqual(system.deactivations, 1, "so other apps' audio plays at full volume again")
        system.finishActivation()
        await settle()

        XCTAssertFalse(handler.isRecording)
        window.isHidden = true
    }

    private func show(_ handler: SpeechHandler) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UIHostingController(
            rootView: ScreenView(screen: screen, viewModel: AIComposerViewModel(), speechHandler: handler)
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
