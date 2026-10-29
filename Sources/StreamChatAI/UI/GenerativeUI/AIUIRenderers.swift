//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The renderers of a conversation's formats, put together so the views they show keep their
/// types all the way into the conversation. ``AIUIHost`` puts its renderers together with
/// ``AIUIRenderersBuilder``, and a single ``AIUIRenderer`` is a set of its own.
@MainActor
public protocol AIUIRenderers {
    /// The view of a document from one of them.
    associatedtype Content: View

    /// Each renderer, in the order they are asked.
    var all: [any AIUIRenderer] { get }

    /// The view of `document` from the first renderer that reads its format and version, or
    /// `nil` when none does, or the one that does shows nothing of its own for the reply.
    func view(for document: AIUIDocument, messageID: String, in context: AIUIRenderingContext) -> Content?
}

extension AIUIRenderers {
    func reads(_ document: AIUIDocument) -> Bool {
        all.contains { $0.format == document.format && $0.supports(version: document.version) }
    }
}

/// Two sets of renderers, the first one asked first, which ``AIUIRenderersBuilder`` puts
/// together.
@MainActor
public struct AIUIRendererPair<First: AIUIRenderers, Second: AIUIRenderers>: AIUIRenderers {
    /// The view of a document from either set.
    public enum Content: View {
        case first(First.Content)
        case second(Second.Content)

        public var body: some View {
            switch self {
            case let .first(content):
                content
            case let .second(content):
                content
            }
        }
    }

    let first: First
    let second: Second

    public var all: [any AIUIRenderer] {
        first.all + second.all
    }

    public func view(for document: AIUIDocument, messageID: String, in context: AIUIRenderingContext) -> Content? {
        if first.reads(document) {
            return first.view(for: document, messageID: messageID, in: context).map(Content.first)
        }
        return second.view(for: document, messageID: messageID, in: context.after(first.all.count)).map(Content.second)
    }
}

/// Puts the renderers of a conversation's formats together, the first one listed asked first.
///
/// ```swift
/// AIUIHost {
///     A2UIRenderer()
///     OpenUIRenderer()
/// } send: { action in
///     try await chat.sendMessage(with: action.label, extraData: action.customData)
/// }
/// ```
@MainActor
@resultBuilder
public enum AIUIRenderersBuilder {
    public static func buildPartialBlock<Renderers: AIUIRenderers>(first: Renderers) -> Renderers {
        first
    }

    public static func buildPartialBlock<Accumulated: AIUIRenderers, Next: AIUIRenderers>(
        accumulated: Accumulated,
        next: Next
    ) -> AIUIRendererPair<Accumulated, Next> {
        AIUIRendererPair(first: accumulated, second: next)
    }
}

/// Where renderers show a reply's document: the conversation's host, and the engines its
/// renderers made, which the host keeps for as long as it is kept.
@MainActor
public struct AIUIRenderingContext {
    let host: any AIUIHosting
    let engines: AIUIEngines
    let position: Int

    // The engine of the renderer at this position, made the first time it is needed.
    func engine<Renderer: AIUIRenderer>(of renderer: Renderer) -> Renderer.Engine {
        if let engine = engines.made[position] as? Renderer.Engine {
            return engine
        }
        let engine = renderer.makeEngine(host: host)
        engines.made[position] = engine
        return engine
    }

    // The context of the renderers after the first `count` of them.
    func after(_ count: Int) -> AIUIRenderingContext {
        AIUIRenderingContext(host: host, engines: engines, position: position + count)
    }
}

// The engines a host's renderers made, by each renderer's position among them.
@MainActor
final class AIUIEngines {
    var made: [Int: any AIUIEngine] = [:]
}
