//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import os
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
struct OpenUIView: View {
    private enum Source {
        case owned(response: String?, isStreaming: Bool)
        case external(OpenUIRuntime)
    }

    private let source: Source
    @State private var owned = OwnedRuntime()
    private let library: ComponentLibrary
    private let toolProvider: (any OpenUIToolProvider)?
    private let initialState: OpenUIObject?
    private let onAction: (@MainActor (ActionEvent) -> Void)?

    /// Renders with an externally owned runtime (call `runtime.update(response:isStreaming:)` as text streams).
    init(runtime: OpenUIRuntime) {
        self.source = .external(runtime)
        self.library = runtime.library
        self.toolProvider = nil
        self.initialState = nil
        self.onAction = nil
    }

    /// Renders a response, managing the runtime internally.
    init(
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

    var body: some View {
        switch source {
        case .external(let runtime):
            OpenUIRuntimeView(runtime: runtime)
        case .owned(let response, let isStreaming):
            let runtime = owned.runtime(
                library: library,
                toolProvider: toolProvider,
                initialState: initialState,
                onAction: onAction,
                response: response,
                isStreaming: isStreaming
            )
            OpenUIRuntimeView(runtime: runtime)
                .onChange(of: response) { _, newValue in
                    runtime.update(response: newValue, isStreaming: isStreaming)
                }
                .onChange(of: isStreaming) { _, newValue in
                    runtime.update(response: response, isStreaming: newValue)
                }
        }
    }
}

// The runtime an `OpenUIView` makes for itself. It is made during the view's first body, so the
// first frame already shows the response, and it follows the latest library, action handler and
// tool provider. A library that parses programs differently needs a new runtime.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
final class OwnedRuntime {
    private var current: OpenUIRuntime?
    private var tools: ForwardingToolProvider?

    nonisolated init() {}

    func runtime(
        library: ComponentLibrary,
        toolProvider: (any OpenUIToolProvider)?,
        initialState: OpenUIObject?,
        onAction: (@MainActor (ActionEvent) -> Void)?,
        response: String?,
        isStreaming: Bool
    ) -> OpenUIRuntime {
        if let current, current.library.parses(like: library), (tools != nil) == (toolProvider != nil) {
            if current.library.identity != library.identity {
                current.adopt(library)
            }
            tools?.update(toolProvider)
            current.onAction = onAction
            return current
        }
        let tools = toolProvider.map(ForwardingToolProvider.init)
        let runtime = OpenUIRuntime(library: library, toolProvider: tools, initialState: initialState)
        runtime.onAction = onAction
        runtime.update(response: response, isStreaming: isStreaming)
        current?.dispose()
        current = runtime
        self.tools = tools
        return runtime
    }
}

// Lets an owned runtime keep its queries while the app passes a new tool provider.
@available(iOS 17.0, macOS 14.0, *)
final class ForwardingToolProvider: OpenUIToolProvider {
    private let target: OSAllocatedUnfairLock<any OpenUIToolProvider>

    init(_ target: any OpenUIToolProvider) {
        self.target = OSAllocatedUnfairLock(initialState: target)
    }

    func update(_ provider: (any OpenUIToolProvider)?) {
        guard let provider else { return }
        target.withLock { $0 = provider }
    }

    var minimumRefreshInterval: TimeInterval {
        target.withLock { $0.minimumRefreshInterval }
    }

    func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue {
        try await callTool(name, arguments: arguments, userInitiated: false)
    }

    func callTool(_ name: String, arguments: OpenUIObject, userInitiated: Bool) async throws -> OpenUIValue {
        let provider = target.withLock { $0 }
        return try await provider.callTool(name, arguments: arguments, userInitiated: userInitiated)
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
struct OpenUINodeView: View {
    let value: OpenUIValue?

    init(value: OpenUIValue?) {
        self.value = value
    }

    var body: some View {
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
struct OpenUIElementView: View {
    let element: ElementNode
    @Environment(OpenUIRuntime.self) private var runtime

    init(element: ElementNode) {
        self.element = element
    }

    var body: some View {
        if let renderer = runtime.library.component(named: element.typeName)?.renderer {
            renderer(ComponentContext(element: element, runtime: runtime))
        }
    }
}
