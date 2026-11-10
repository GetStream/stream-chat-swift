//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A fully featured prompt-composer surface for AI chat applications.
///
/// `AIComposerView` is generic over a ``AIComposerViewFactory`` so you can swap out any
/// individual slot — the leading attachment button, the central input area, the
/// trailing action area, or the attachment picker sheet — without rebuilding the
/// whole composer from scratch.
///
/// ## Basic usage
///
/// ```swift
/// AIComposerView { message in
///     send(message)
/// }
/// ```
///
/// ## Custom factory
///
/// ```swift
/// AIComposerView(viewFactory: MyFactory()) { message in
///     send(message)
/// }
/// ```
///
/// Pass a ``AIComposerViewModel`` instance if you need to control focus, inject
/// pre-filled text, or manage chat-option chips from outside the view:
///
/// ```swift
/// @StateObject private var composerViewModel = AIComposerViewModel()
///
/// AIComposerView(viewModel: composerViewModel) { message in
///     send(message)
/// }
/// ```
///
/// - Note: Before iOS 16 the text field is a single line, the attachment sheet opens at full
///   height, and the sheet has no button that browses the whole photo library.
@available(iOS 15.0, macOS 12.0, *)
public struct AIComposerView<ComposerFactory: AIComposerViewFactory>: View {
    private let viewFactory: ComposerFactory

    // The view model the composer keeps: the first one it is given, or one of its own.
    @StateObject var viewModel: AIComposerViewModel
    // The view model it shows instead, such as its conversation's, which another conversation
    // replaces.
    let followedViewModel: AIComposerViewModel?
    @StateObject var speechHandler: SpeechHandler = .init()

    var onMessageSend: (MessageData) -> Void
    var onStopGenerating: (() -> Void)?

    public init(
        viewFactory: ComposerFactory = DefaultAIComposerViewFactory.shared,
        viewModel: AIComposerViewModel? = nil,
        onMessageSend: @escaping (MessageData) -> Void,
        onStopGenerating: (() -> Void)? = nil
    ) {
        self.viewFactory = viewFactory
        _viewModel = StateObject(wrappedValue: viewModel ?? AIComposerViewModel())
        followedViewModel = nil
        self.onMessageSend = onMessageSend
        self.onStopGenerating = onStopGenerating
    }

    init(
        viewFactory: ComposerFactory,
        following viewModel: AIComposerViewModel,
        onMessageSend: @escaping (MessageData) -> Void,
        onStopGenerating: (() -> Void)?
    ) {
        self.viewFactory = viewFactory
        // Unused while it follows `viewModel`.
        _viewModel = StateObject(wrappedValue: AIComposerViewModel())
        followedViewModel = viewModel
        self.onMessageSend = onMessageSend
        self.onStopGenerating = onStopGenerating
    }

    public var body: some View {
        AIComposerContentView(
            viewFactory: viewFactory,
            viewModel: followedViewModel ?? viewModel,
            speechHandler: speechHandler,
            onMessageSend: onMessageSend,
            onStopGenerating: onStopGenerating
        )
    }
}
