//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A fully featured prompt-composer surface for AI chat applications.
///
/// `ComposerView` is generic over a ``ComposerViewFactory`` so you can swap out any
/// individual slot — the leading attachment button, the central input area, the
/// trailing action area, or the attachment picker sheet — without rebuilding the
/// whole composer from scratch.
///
/// ## Basic usage
///
/// ```swift
/// ComposerView { message in
///     send(message)
/// }
/// ```
///
/// ## Custom factory
///
/// ```swift
/// ComposerView(viewFactory: MyFactory()) { message in
///     send(message)
/// }
/// ```
///
/// Pass a ``ComposerViewModel`` instance if you need to control focus, inject
/// pre-filled text, or manage chat-option chips from outside the view:
///
/// ```swift
/// @StateObject private var composerViewModel = ComposerViewModel()
///
/// ComposerView(viewModel: composerViewModel) { message in
///     send(message)
/// }
/// ```
///
/// - Note: Requires iOS 16 or later.
@available(iOS 16, *)
public struct ComposerView<ComposerFactory: ComposerViewFactory>: View {
    private let viewFactory: ComposerFactory

    @StateObject var viewModel: ComposerViewModel
    @StateObject var speechHandler: SpeechHandler = .init()

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var isGenerating: Bool

    var onMessageSend: (MessageData) -> Void
    var onStopGenerating: (() -> Void)?

    public init(
        viewFactory: ComposerFactory = DefaultViewFactory.shared,
        viewModel: ComposerViewModel? = nil,
        isGenerating: Bool = false,
        onMessageSend: @escaping (MessageData) -> Void,
        onStopGenerating: (() -> Void)? = nil
    ) {
        self.viewFactory = viewFactory
        _viewModel = StateObject(wrappedValue: viewModel ?? ComposerViewModel())
        self.onMessageSend = onMessageSend
        self.isGenerating = isGenerating
        self.onStopGenerating = onStopGenerating
    }
    
    public var body: some View {
        HStack {
            viewFactory.makeLeadingComposerView(
                options: .init(onTap: {
                    viewModel.sheetShown = true
                })
            )
            
            viewFactory.makeComposerInputView(
                options: .init(
                    viewModel: viewModel,
                    speechHandler: speechHandler,
                    isGenerating: isGenerating,
                    onMessageSend: onMessageSend,
                    onStopGenerating: onStopGenerating
                )
            )

            viewFactory.makeTrailingComposerView(options: .init())
        }
        .padding(.all, layout.spacingXs)
        .foregroundStyle(Color(colors.composerText))
        .sheet(isPresented: $viewModel.sheetShown) {
            viewFactory.makeComposerPickerView(options: .init(viewModel: viewModel))
                .presentationDetents([.medium, .large])
        }
    }
}
