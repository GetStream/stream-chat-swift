//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Configuration passed to ``AIComposerViewFactory/makeLeadingComposerView(options:)``.
public struct AIComposerLeadingViewOptions {
    /// Called when the user taps the leading button to open the attachment picker.
    public var onTap: () -> Void

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }
}

/// Configuration passed to ``AIComposerViewFactory/makeTrailingComposerView(options:)``.
///
/// Currently empty; reserved for future additions.
public struct AIComposerTrailingViewOptions {
    public init() {}
}

/// Configuration passed to ``AIComposerViewFactory/makeComposerInputView(options:)``.
public struct AIComposerInputViewOptions {
    /// The shared view model that holds text, attachments, and chat-option state.
    public var viewModel: AIComposerViewModel
    /// The shared speech handler owned by ``AIComposerView``. Passing it through options
    /// rather than letting ``AIComposerInputView`` own it keeps the handler alive at the
    /// outermost view level, preventing identity resets when the input area is recreated.
    public var speechHandler: SpeechHandler
    /// Called with the composed ``MessageData`` when the user taps send.
    public var onMessageSend: (MessageData) -> Void
    /// Called when the user taps the stop-generating button. `nil` if stopping is not
    /// supported by the host.
    public var onStopGenerating: (() -> Void)?

    public init(
        viewModel: AIComposerViewModel,
        speechHandler: SpeechHandler,
        onMessageSend: @escaping (MessageData) -> Void,
        onStopGenerating: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.speechHandler = speechHandler
        self.onMessageSend = onMessageSend
        self.onStopGenerating = onStopGenerating
    }
}

/// Configuration passed to ``AIComposerViewFactory/makeComposerInputTrailingView(options:)``.
public struct AIComposerInputTrailingViewOptions {
    /// The shared view model; the default dictation button writes its transcript to `text`.
    public var viewModel: AIComposerViewModel
    /// The shared speech handler owned by ``AIComposerView``.
    public var speechHandler: SpeechHandler

    public init(viewModel: AIComposerViewModel, speechHandler: SpeechHandler) {
        self.viewModel = viewModel
        self.speechHandler = speechHandler
    }
}

/// Configuration passed to ``AIComposerViewFactory/makeComposerPickerView(options:)``.
public struct AIComposerPickerViewOptions {
    /// The shared view model used to read and write attachment and chat-option state.
    public var viewModel: AIComposerViewModel

    public init(viewModel: AIComposerViewModel) {
        self.viewModel = viewModel
    }
}
