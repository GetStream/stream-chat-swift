//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The renderers of a conversation's formats, in the order they are asked, put together so the
/// views they show keep their types all the way into the conversation. ``AIUIHost`` puts its
/// renderers together with ``AIUIRendererListBuilder``, and a single ``AIUIRenderer`` is a list
/// of its own.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public protocol AIUIRendererList {
    /// The view of a document from one of them.
    associatedtype Content: View

    /// Each renderer, in the order they are asked.
    var all: [any AIUIRenderer] { get }

    /// The view of `document` from the first renderer that reads its format and version, or
    /// `nil` when none does, or the one that does shows nothing of its own for the reply.
    func view(for document: AIUIDocument, messageID: String, in context: AIUIRenderingContext) -> Content?
}

@available(iOS 15.0, macOS 12.0, *)
extension AIUIRendererList {
    func reads(_ document: AIUIDocument) -> Bool {
        all.contains { $0.format == document.format && $0.supports(version: document.version) }
    }

    // Gives a reply's document to the engine of the first renderer that reads its format and
    // version.
    func receive(_ document: AIUIDocument, messageID: String, in context: AIUIRenderingContext) {
        guard let position = all.firstIndex(where: { $0.reads(document) }) else { return }
        all[position].deliver(document, messageID: messageID, in: context.after(position))
    }

    // Tells the engine that took a reply's last document that the reply, or its UI, is gone.
    func remove(_ document: AIUIDocument, messageID: String, in context: AIUIRenderingContext) {
        guard let position = all.firstIndex(where: { $0.reads(document) }) else { return }
        all[position].forget(messageID: messageID, in: context.after(position))
    }
}

/// Two lists of renderers, the first one asked first, which ``AIUIRendererListBuilder`` puts
/// together.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public struct AIUIRendererPair<First: AIUIRendererList, Second: AIUIRendererList>: AIUIRendererList {
    /// The view of a document from either list.
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
@available(iOS 15.0, macOS 12.0, *)
@MainActor
@resultBuilder
public enum AIUIRendererListBuilder {
    public static func buildPartialBlock<Renderers: AIUIRendererList>(first: Renderers) -> Renderers {
        first
    }

    public static func buildPartialBlock<Accumulated: AIUIRendererList, Next: AIUIRendererList>(
        accumulated: Accumulated,
        next: Next
    ) -> AIUIRendererPair<Accumulated, Next> {
        AIUIRendererPair(first: accumulated, second: next)
    }
}

/// Where renderers show a reply's document: the conversation's host, and the engines its
/// renderers made, which the host keeps for as long as it is kept.
@available(iOS 15.0, macOS 12.0, *)
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
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class AIUIEngines {
    var made: [Int: any AIUIEngine] = [:]
}
