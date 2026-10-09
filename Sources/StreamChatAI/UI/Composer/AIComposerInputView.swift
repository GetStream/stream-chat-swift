//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// The default central input area rendered by ``AIComposerView``.
///
/// Contains a multi-line `TextField`, an inline ``SpeechToTextButton``, a send
/// button, and a stop-generating button. It also shows attachment thumbnails and
/// the active chat-option chip when those are present on the view model.
///
/// `AIComposerInputView` observes ``AIComposerViewModel/isTextFieldFocused`` and keeps
/// the keyboard in sync: set `isTextFieldFocused = true` to programmatically focus
/// the field and `false` to dismiss the keyboard.
///
/// Override ``AIComposerViewFactory/makeComposerInputView(options:)`` to replace this
/// view with your own implementation while keeping the rest of the composer intact.
@available(iOS 16, *)
public struct AIComposerInputView<TrailingView: View>: View {
    @ObservedObject var viewModel: AIComposerViewModel
    @ObservedObject var speechHandler: SpeechHandler

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// Shown inside the field while it is empty and nothing is generating.
    private let trailingView: TrailingView

    var onMessageSend: (MessageData) -> Void
    var onStopGenerating: (() -> Void)?

    @FocusState var isFocused: Bool

    public init(
        viewModel: AIComposerViewModel,
        speechHandler: SpeechHandler,
        trailingView: TrailingView,
        onMessageSend: @escaping (MessageData) -> Void,
        onStopGenerating: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.speechHandler = speechHandler
        self.trailingView = trailingView
        self.onMessageSend = onMessageSend
        self.onStopGenerating = onStopGenerating
    }
    
    public var body: some View {
        VStack(spacing: layout.spacingMd) {
            if !viewModel.attachments.isEmpty {
                SelectedAttachmentsRow(viewModel: viewModel)
            }
            
            if let selectedChatOption = viewModel.selectedChatOption {
                SelectedChatOptionChip(option: selectedChatOption) {
                    withAnimation {
                        viewModel.selectedChatOption = nil
                    }
                }
            }
            
            HStack {
                TextField(L10n.Composer.placeholderAskAnything, text: $viewModel.text, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                
                actions
            }
        }
        .padding(.all, layout.spacingSm)
        .background(Color(colors.composerBackground))
        .cornerRadius(layout.radius3xl)
        .onAppear {
            if viewModel.isTextFieldFocused {
                isFocused = true
            }
        }
        .onChange(of: viewModel.isTextFieldFocused) { newValue in
            isFocused = newValue
        }
        .onChange(of: viewModel.text) { newText in
            if newText.isEmpty && speechHandler.isRecording {
                speechHandler.stop()
            }
        }
    }

    // The trailing view, the send button and the stop button share one spot and only fade in
    // and out, so the field never changes width as you type.
    private var actions: some View {
        ZStack {
            trailingView
                .fontWeight(.semibold)
                .opacity(viewModel.isGenerating ? 0 : (text.isEmpty ? 1 : 0))
            
            Button {
                send()
            } label: {
                images.composerSend
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22)
            }
            .opacity(viewModel.isGenerating ? 0 : (text.isEmpty ? 0 : 1))
            
            Button {
                onStopGenerating?()
            } label: {
                images.composerStopGenerating
                    .foregroundStyle(Color(colors.composerIcon))
            }
            .opacity(viewModel.isGenerating ? 1 : 0)
        }
    }

    private func send() {
        onMessageSend(.init(text: text, attachments: viewModel.attachments, chatOption: viewModel.selectedChatOption))
        viewModel.clearAfterSending()
        if speechHandler.isRecording {
            speechHandler.stop()
        }
    }

    var text: String {
        viewModel.text
    }
}

@available(iOS 16, *)
public extension AIComposerInputView where TrailingView == SpeechToTextButton {
    /// Creates the input with the default ``SpeechToTextButton`` inside the field.
    init(
        viewModel: AIComposerViewModel,
        speechHandler: SpeechHandler,
        onMessageSend: @escaping (MessageData) -> Void,
        onStopGenerating: (() -> Void)? = nil
    ) {
        self.init(
            viewModel: viewModel,
            speechHandler: speechHandler,
            trailingView: SpeechToTextButton(speechHandler: speechHandler) { newText in
                viewModel.text = newText
            },
            onMessageSend: onMessageSend,
            onStopGenerating: onStopGenerating
        )
    }
}
