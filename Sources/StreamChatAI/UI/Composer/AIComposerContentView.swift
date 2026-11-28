//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

// What an AIComposerView shows, which follows the view model it is given.
@available(iOS 15.0, macOS 12.0, *)
struct AIComposerContentView<ComposerFactory: AIComposerViewFactory>: View {
    let viewFactory: ComposerFactory
    @ObservedObject var viewModel: AIComposerViewModel
    let speechHandler: SpeechHandler
    let onMessageSend: (MessageData) -> Void
    let onStopGenerating: (() -> Void)?

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        HStack(spacing: layout.spacingXs) {
            viewFactory.makeLeadingComposerView(
                options: .init(onTap: {
                    viewModel.sheetShown = true
                })
            )

            viewFactory.makeComposerInputView(
                options: .init(
                    viewModel: viewModel,
                    speechHandler: speechHandler,
                    onMessageSend: onMessageSend,
                    onStopGenerating: onStopGenerating
                )
            )

            viewFactory.makeTrailingComposerView(options: .init())
        }
        .padding(.all, layout.spacingXs)
        .foregroundStyle(Color(colors.composerText))
        .sheet(isPresented: $viewModel.sheetShown) {
            let picker = viewFactory.makeComposerPickerView(options: .init(viewModel: viewModel))
            if #available(iOS 16, *) {
                picker.presentationDetents([.medium, .large])
            } else {
                picker
            }
        }
        .onDisappear {
            // Ends dictation, which silences other audio while it is active, or cancels it while
            // it still waits for a permission or the audio session, so it doesn't start off screen.
            speechHandler.stop()
        }
        .onChange(of: ObjectIdentifier(viewModel)) { _ in
            // What the person says belongs in the draft they started it in, not another
            // conversation's.
            speechHandler.stop()
        }
    }
}
