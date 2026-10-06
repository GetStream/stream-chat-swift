//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Configuration passed to ``ComposerViewFactory/makeLeadingComposerView(options:)``.
public struct LeadingComposerViewOptions {
    /// Called when the user taps the leading button to open the attachment picker.
    public var onTap: () -> Void
}

/// Configuration passed to ``ComposerViewFactory/makeTrailingComposerView(options:)``.
///
/// Currently empty; reserved for future additions.
public struct TrailingComposerViewOptions {}

/// Configuration passed to ``ComposerViewFactory/makeComposerInputView(options:)``.
public struct ComposerInputViewOptions {
    /// The shared view model that holds text, attachments, and chat-option state.
    public var viewModel: ComposerViewModel
    /// The shared speech handler owned by ``ComposerView``. Passing it through options
    /// rather than letting ``ComposerInputView`` own it keeps the handler alive at the
    /// outermost view level, preventing identity resets when the input area is recreated.
    public var speechHandler: SpeechHandler
    /// `true` while an AI response is being streamed; hides the send button and shows
    /// the stop-generating control.
    public let isGenerating: Bool
    /// Called with the composed ``MessageData`` when the user taps send.
    let onMessageSend: (MessageData) -> Void
    /// Called when the user taps the stop-generating button. `nil` if stopping is not
    /// supported by the host.
    let onStopGenerating: (() -> Void)?
}

/// Configuration passed to ``ComposerViewFactory/makeComposerInputTrailingView(options:)``.
public struct ComposerInputTrailingViewOptions {
    /// The shared view model; the default dictation button writes its transcript to `text`.
    public var viewModel: ComposerViewModel
    /// The shared speech handler owned by ``ComposerView``.
    public var speechHandler: SpeechHandler
}

/// Configuration passed to ``ComposerViewFactory/makeComposerPickerView(options:)``.
public struct ComposerPickerViewOptions {
    /// The shared view model used to read and write attachment and chat-option state.
    public var viewModel: ComposerViewModel
}
