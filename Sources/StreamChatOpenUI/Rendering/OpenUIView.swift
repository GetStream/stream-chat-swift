//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Renders an OpenUI Lang response with native SwiftUI components.
///
/// ```swift
/// // Simple: the view owns its runtime.
/// OpenUIView(response: text, isStreaming: isStreaming, library: .openUIChat) { event in
///     if event.isContinueConversation { send(event.humanFriendlyMessage) }
/// }
///
/// // Chat lists: keep one runtime per message so state survives cell reuse.
/// OpenUIView(runtime: message.runtime)
/// ```
@available(iOS 17.0, macOS 14.0, *)
public struct OpenUIView: View {
    private enum Source {
        case owned(response: String?, isStreaming: Bool)
        case external(OpenUIRuntime)
    }

    private let source: Source
    @State private var ownedRuntime: OpenUIRuntime?
    private let library: ComponentLibrary
    private let toolProvider: (any OpenUIToolProvider)?
    private let initialState: OpenUIObject?
    private let onAction: (@MainActor (ActionEvent) -> Void)?

    /// Renders with an externally owned runtime (call `runtime.update(response:isStreaming:)` as text streams).
    public init(runtime: OpenUIRuntime) {
        self.source = .external(runtime)
        self.library = runtime.library
        self.toolProvider = nil
        self.initialState = nil
        self.onAction = nil
    }

    /// Renders a response, managing the runtime internally.
    public init(
        response: String?,
        isStreaming: Bool = false,
        library: ComponentLibrary = .openUIChat,
        toolProvider: (any OpenUIToolProvider)? = nil,
        initialState: OpenUIObject? = nil,
        onAction: (@MainActor (ActionEvent) -> Void)? = nil
    ) {
        self.source = .owned(response: response, isStreaming: isStreaming)
        self.library = library
        self.toolProvider = toolProvider
        self.initialState = initialState
        self.onAction = onAction
    }

    public var body: some View {
        switch source {
        case .external(let runtime):
            OpenUIRuntimeView(runtime: runtime)
        case .owned(let response, let isStreaming):
            Group {
                if let ownedRuntime {
                    OpenUIRuntimeView(runtime: ownedRuntime)
                } else {
                    Color.clear.frame(height: 0)
                }
            }
            .onAppear {
                if ownedRuntime == nil {
                    let runtime = OpenUIRuntime(library: library, toolProvider: toolProvider, initialState: initialState)
                    runtime.onAction = onAction
                    runtime.update(response: response, isStreaming: isStreaming)
                    ownedRuntime = runtime
                }
            }
            .onChange(of: response) { _, newValue in
                ownedRuntime?.update(response: newValue, isStreaming: isStreaming)
            }
            .onChange(of: isStreaming) { _, newValue in
                ownedRuntime?.update(response: response, isStreaming: newValue)
            }
        }
    }
}

/// Renders the evaluated root of a runtime.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUIRuntimeView: View {
    let runtime: OpenUIRuntime
    @Environment(\.openUITheme) private var theme

    var body: some View {
        if let root = runtime.root {
            OpenUIElementView(element: root)
                .environment(runtime)
                .opacity(runtime.isQueryLoading ? 0.7 : 1)
                .overlay(alignment: .topTrailing) {
                    if runtime.isQueryLoading {
                        ProgressView()
                            .controlSize(.small)
                            .padding(theme.spacing.s)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: runtime.isQueryLoading)
        }
    }
}

/// Renders any value produced by the parser/evaluator: elements, arrays (as siblings) and primitives.
@available(iOS 17.0, macOS 14.0, *)
public struct OpenUINodeView: View {
    let value: OpenUIValue?

    public init(value: OpenUIValue?) {
        self.value = value
    }

    public var body: some View {
        switch value {
        case .element(let element)?:
            OpenUIElementView(element: element)
        case .array(let items)?:
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                OpenUINodeView(value: item)
            }
        case .string(let string)?:
            Text(string)
        case .number(let number)?:
            Text(JS.numberToString(number))
        case .bool(let bool)?:
            Text(bool ? "true" : "false")
        case .null?, .object?, .expression?, nil:
            EmptyView()
        }
    }
}

/// Renders a single element with its library renderer. Unknown and data-only components render nothing.
@available(iOS 17.0, macOS 14.0, *)
public struct OpenUIElementView: View {
    let element: ElementNode
    @Environment(OpenUIRuntime.self) private var runtime

    public init(element: ElementNode) {
        self.element = element
    }

    public var body: some View {
        if let renderer = runtime.library.component(named: element.typeName)?.renderer {
            renderer(ComponentContext(element: element, runtime: runtime))
        }
    }
}
