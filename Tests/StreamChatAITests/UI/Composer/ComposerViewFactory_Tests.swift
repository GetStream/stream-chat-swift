//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import SwiftUI
import XCTest

@available(iOS 16, *)
@MainActor
final class ComposerViewFactory_Tests: XCTestCase {
    func testTheInputDictatesByDefault() {
        let input = DefaultViewFactory.shared.makeComposerInputView(options: inputOptions())

        XCTAssertTrue(input is ComposerInputView<SpeechToTextButton>)
    }

    func testAFactoryReplacesTheViewInsideTheInput() {
        let input = NoDictationFactory().makeComposerInputView(options: inputOptions())

        XCTAssertTrue(input is ComposerInputView<EmptyView>)
    }

    private func inputOptions() -> ComposerInputViewOptions {
        ComposerInputViewOptions(
            viewModel: ComposerViewModel(),
            speechHandler: SpeechHandler(),
            isGenerating: false,
            onMessageSend: { _ in },
            onStopGenerating: nil
        )
    }
}

@available(iOS 16, *)
private final class NoDictationFactory: ComposerViewFactory {
    func makeComposerInputTrailingView(options: ComposerInputTrailingViewOptions) -> some View {
        EmptyView()
    }
}
