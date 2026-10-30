//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// Reads one format of generated UI and shows it. The SDK knows no format of its own: give a
/// conversation's ``AIUIHost`` the renderer of each format your agent writes, such as OpenUI's.
///
/// A renderer places the host's components by name, among the ones its format has. The view its
/// engine makes is the one the conversation shows, with its type, so SwiftUI updates it as it
/// does any other view.
@MainActor
public protocol AIUIRenderer: AIUIRenderers where Content == Engine.Content {
    /// What shows the documents of one conversation.
    associatedtype Engine: AIUIEngine

    /// The format it reads.
    var format: AIUIFormat { get }
    /// Whether it reads documents of `version`, or of no version when `nil`. It reads every
    /// version by default.
    func supports(version: String?) -> Bool
    /// What the agent's backend needs to have its model write UI this renderer shows with
    /// `components`, such as the model's instructions. None by default.
    func capabilities(components: [any AIUIComponent]) -> [String: RawJSON]
    /// Makes what shows the documents of one conversation. Keep `host` weakly: it keeps the
    /// engine.
    func makeEngine(host: any AIUIHosting) -> Engine
}

public extension AIUIRenderer {
    func supports(version: String?) -> Bool { true }
    func capabilities(components: [any AIUIComponent]) -> [String: RawJSON] { [:] }

    var all: [any AIUIRenderer] { [self] }

    func view(for document: AIUIDocument, messageID: String, in context: AIUIRenderingContext) -> Engine.Content? {
        guard format == document.format, supports(version: document.version) else { return nil }
        return context.engine(of: self).view(for: document, messageID: messageID)
    }
}

extension AIUIRenderer {
    // Gives a reply's document to its engine, the one in `context`.
    func deliver(_ document: AIUIDocument, messageID: String, in context: AIUIRenderingContext) {
        context.engine(of: self).receive(document, messageID: messageID)
    }
}

/// Shows the documents of one renderer in one conversation. The host makes one per renderer and
/// keeps it while it is kept, so an engine can hold each reply's state, and a format whose
/// later replies change an earlier one's UI can follow the conversation.
@MainActor
public protocol AIUIEngine: AnyObject {
    /// The view of a reply's document.
    associatedtype Content: View

    /// Takes a reply's document as it arrives or changes, oldest reply first, whether or not the
    /// reply is on screen, so a format whose later replies change an earlier one's UI can follow
    /// them all. It comes as the conversation updates, before any reply's view is asked for:
    /// change what is already on screen after the update, such as in a `Task`. Nothing by
    /// default.
    func receive(_ document: AIUIDocument, messageID: String)

    /// The view of a reply's document, or `nil` when it shows nothing of its own, such as a
    /// reply that only changed an earlier one's UI, so the reply's text shows. It is asked
    /// again only as the reply's own document changes, so a view that later replies change
    /// follows the engine's state, such as an object it observes.
    func view(for document: AIUIDocument, messageID: String) -> Content?
}

public extension AIUIEngine {
    func receive(_ document: AIUIDocument, messageID: String) { /* Each reply's UI is its own. */ }
}
