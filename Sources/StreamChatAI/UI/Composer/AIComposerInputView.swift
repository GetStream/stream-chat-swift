//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// The default central input area rendered by ``AIComposerView``.
///
/// Contains a multi-line `TextField` (a single line before iOS 16), an inline
/// ``SpeechToTextButton``, a send button, and a stop-generating button. It also shows
/// attachment thumbnails and the active chat-option chip when those are present on the view model,
/// and, while ``AIComposerViewModel/isEditing``, that the person is editing a message.
///
/// `AIComposerInputView` observes ``AIComposerViewModel/isTextFieldFocused`` and keeps
/// the keyboard in sync: set `isTextFieldFocused = true` to programmatically focus
/// the field and `false` to dismiss the keyboard.
///
/// Override ``AIComposerViewFactory/makeComposerInputView(options:)`` to replace this
/// view with your own implementation while keeping the rest of the composer intact.
@available(iOS 15.0, macOS 12.0, *)
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
            if viewModel.isEditing {
                EditingMessageChip {
                    withAnimation {
                        viewModel.cancelEditing()
                    }
                }
            }

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
            
            HStack(spacing: layout.spacingXs) {
                textField

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
        .onChange(of: isFocused) { newValue in
            // So setting it again focuses the field after the person dismissed the keyboard.
            if viewModel.isTextFieldFocused != newValue {
                viewModel.isTextFieldFocused = newValue
            }
        }
        .onChange(of: viewModel.text) { newText in
            if newText.isEmpty {
                speechHandler.stop()
            }
        }
    }

    // Before iOS 16 a text field can't grow as its text wraps, so it stays one line.
    @ViewBuilder
    private var textField: some View {
        if #available(iOS 16, *) {
            TextField(L10n.Composer.placeholderAskAnything, text: $viewModel.text, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .focused($isFocused)
        } else {
            TextField(L10n.Composer.placeholderAskAnything, text: $viewModel.text)
                .textFieldStyle(.plain)
                .focused($isFocused)
        }
    }

    // The trailing view, the send button and the stop button share one spot and only fade in
    // and out, so the field never changes width as you type.
    private var actions: some View {
        ZStack {
            trailingView
                .opacity(viewModel.isGenerating ? 0 : (canSend ? 0 : 1))
            
            Button {
                send()
            } label: {
                images.composerSend
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: layout.buttonVisualHeightXs)
            }
            .opacity(viewModel.isGenerating ? 0 : (canSend ? 1 : 0))
            
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
        guard canSend else { return }
        // Stopped first, also while it is starting, so what it hears doesn't come back into the
        // empty composer.
        speechHandler.stop()
        onMessageSend(.init(text: text, attachments: viewModel.attachments, chatOption: viewModel.selectedChatOption))
        viewModel.clearAfterSending()
    }

    var text: String {
        viewModel.text
    }

    // Something to send: text, or files without text.
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !viewModel.attachments.isEmpty
    }
}

@available(iOS 15.0, macOS 12.0, *)
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
