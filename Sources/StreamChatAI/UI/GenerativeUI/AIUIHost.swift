//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

/// What a reply's UI can do in its conversation: place the app's components, tell the agent what
/// the person did, run the app's tools, open links and keep its state. The conversation's
/// ``AIUIHost`` does it for renderers and components.
@MainActor
public protocol AIUIHosting: AnyObject, Sendable {
    /// The app's components, which every renderer can place.
    var components: [any AIUIComponent] { get }
    /// Sends what the person did to the agent.
    func send(_ action: AIUIAction)
    /// Runs one of the app's tools for a reply's UI, such as to load data on this device.
    /// - Returns: The tool's output.
    func runTool(_ name: String, arguments: [String: RawJSON]) async throws -> RawJSON
    /// Opens a link from a reply's UI.
    func open(_ url: URL)
    /// The state a reply's UI was left in, such as a form's values.
    func state(for messageID: String) -> RawJSON?
    /// Keeps the state a reply's UI was left in.
    func setState(_ state: RawJSON?, for messageID: String)
}

public extension AIUIHosting {
    /// The app's component the agent places by `name`.
    func component(named name: String) -> (any AIUIComponent)? {
        components.first { $0.name == name }
    }
}

/// The generated UI of one conversation: the renderers of the formats it reads, the app's
/// components, and where what the person does in it goes.
///
/// A reply carries its UI as an ``AIUIDocument``, which shows in place of its text when one of
/// the host's renderers reads its format. Keep one host for as long as its conversation shows,
/// so each reply's UI keeps its state. The renderers keep their types, so the UI a reply shows is
/// the view its renderer made.
///
/// ```swift
/// let ui = AIUIHost(components: [PlaceCardComponent()]) {
///     A2UIRenderer()
///     OpenUIRenderer()
/// } send: { action in
///     try await chat.sendMessage(with: action.label, extraData: action.customData)
/// }
///
/// AIConversationView(messages: messages, ui: ui)
/// ```
@MainActor
public final class AIUIHost<Renderers: AIUIRenderers>: AIUIHosting, ObservableObject {
    /// The renderers of the formats it reads, the first one listed asked first.
    public let renderers: Renderers
    public let components: [any AIUIComponent]

    private let tools: [String: any AIClientTool]
    private let sendAction: @MainActor (AIUIAction) async throws -> Void
    private let engines = AIUIEngines()
    private var states: [String: RawJSON] = [:]
    private var received: [String: AIUIDocument] = [:]

    /// - Parameters:
    ///   - components: The app's views the agent can place.
    ///   - tools: The app's tools a reply's UI can run, to load data on this device.
    ///   - renderers: The renderer of each format the agent writes.
    ///   - send: Sends what the person did to the agent, as their next message.
    public init(
        components: [any AIUIComponent] = [],
        tools: [any AIClientTool] = [],
        @AIUIRenderersBuilder renderers: () -> Renderers,
        send: @escaping @MainActor (AIUIAction) async throws -> Void
    ) {
        self.renderers = renderers()
        self.components = components
        self.tools = Dictionary(tools.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        sendAction = send
    }

    /// Whether one of its renderers reads `document`. The one that does can still show nothing
    /// of its own for a reply, which then shows its text, as ``AIUIView/canShow`` tells.
    public func canShow(_ document: AIUIDocument) -> Bool {
        renderers.reads(document)
    }

    public func send(_ action: AIUIAction) {
        Task { @MainActor in
            do {
                try await sendAction(action)
            } catch {
                log.error("Couldn't send what the person did in a reply's UI", error: error)
            }
        }
    }

    public func runTool(_ name: String, arguments: [String: RawJSON] = [:]) async throws -> RawJSON {
        guard let tool = tools[name] else {
            throw AIUIToolError(message: "No tool named \(name)")
        }
        let call = AIToolCallPart(
            id: UUID().uuidString,
            name: name,
            status: .awaitingClient,
            executor: .client,
            arguments: try JSONEncoder().encode(arguments)
        )
        let result = await tool.run(call)
        if let failure = result.failure {
            throw AIUIToolError(message: failure)
        }
        guard let output = result.output else { return .nil }
        return try JSONDecoder().decode(RawJSON.self, from: output)
    }

    public func open(_ url: URL) {
        UIApplication.shared.open(url)
    }

    /// The state a reply's UI was left in, such as a form's values, kept while the host is.
    public func state(for messageID: String) -> RawJSON? {
        states[messageID]
    }

    public func setState(_ state: RawJSON?, for messageID: String) {
        states[messageID] = state
    }

    /// Gives its renderers the UI of the conversation's replies, oldest first, as each arrives or
    /// changes, whether or not the reply is on screen, so a format whose later replies change an
    /// earlier one's UI follows them all. ``AIConversationView`` does it: call it with the
    /// conversation's messages when you show replies yourself with ``AIUIView``.
    public func receive<Message: AIMessage>(_ messages: [Message]) {
        for message in messages where message.role != .user {
            guard let document = message.uiDocument else { continue }
            let messageID = String(describing: message.id)
            guard received[messageID] != document else { continue }
            received[messageID] = document
            renderers.receive(document, messageID: messageID, in: context)
        }
    }

    /// What the agent's backend needs to write UI this app shows: each format it reads, with
    /// what its renderer adds, and the app's components.
    public var capabilities: [String: RawJSON] {
        let formats = renderers.all.map { renderer -> RawJSON in
            var fields = renderer.capabilities(components: components)
            fields["format"] = .string(renderer.format.rawValue)
            return .dictionary(fields)
        }
        let definitions = components.compactMap { component -> RawJSON? in
            do {
                return try JSONDecoder().decode(RawJSON.self, from: JSONEncoder().encode(component.definition))
            } catch {
                log.error("Couldn't describe the component \(component.name) to the agent", error: error)
                return nil
            }
        }
        return ["v": .number(1), "renderers": .array(formats), "components": .array(definitions)]
    }

    // The view of a reply's document from the first renderer that reads its format and version.
    func content(for document: AIUIDocument, messageID: String) -> Renderers.Content? {
        renderers.view(for: document, messageID: messageID, in: context)
    }

    // Where its renderers show the documents of its conversation, with the engines it keeps.
    private var context: AIUIRenderingContext {
        AIUIRenderingContext(host: self, engines: engines, position: 0)
    }
}

struct AIUIToolError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
