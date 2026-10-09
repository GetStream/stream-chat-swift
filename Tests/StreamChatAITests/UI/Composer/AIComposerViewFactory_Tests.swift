//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import SwiftUI
import XCTest

@available(iOS 16, *)
@MainActor
final class AIComposerViewFactory_Tests: XCTestCase {
    func testTheInputDictatesByDefault() {
        let input = DefaultAIComposerViewFactory.shared.makeComposerInputView(options: inputOptions())

        XCTAssertTrue(input is AIComposerInputView<SpeechToTextButton>)
    }

    func testAFactoryReplacesTheViewInsideTheInput() {
        let input = NoDictationFactory().makeComposerInputView(options: inputOptions())

        XCTAssertTrue(input is AIComposerInputView<EmptyView>)
    }

    private func inputOptions() -> AIComposerInputViewOptions {
        AIComposerInputViewOptions(
            viewModel: AIComposerViewModel(),
            speechHandler: SpeechHandler(),
            onMessageSend: { _ in },
            onStopGenerating: nil
        )
    }
}

@available(iOS 16, *)
private final class NoDictationFactory: AIComposerViewFactory {
    func makeComposerInputTrailingView(options: AIComposerInputTrailingViewOptions) -> some View {
        EmptyView()
    }
}
