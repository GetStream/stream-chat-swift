//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

/// What a reply's UI can do in its conversation: place the app's components, tell the agent what
/// the person did, run the app's tools, open links and keep its state. The conversation's
/// ``AIUIHost`` does it for renderers and components.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public protocol AIUIHosting: AnyObject, Sendable {
    /// The app's components, which every renderer can place.
    var components: [any AIUIComponent] { get }
    /// Sends what the person did to the agent.
    func send(_ action: AIUIAction)
    /// Runs one of the app's tools for a reply's UI, such as to load data on this device.
    /// - Parameter userInitiated: Whether the person asked for it, such as with a tap, rather
    ///   than the UI while it shows. Only a read-only tool runs when they didn't.
    /// - Returns: The tool's output.
    func runTool(_ name: String, arguments: [String: RawJSON], userInitiated: Bool) async throws -> RawJSON
    /// Opens a link from a reply's UI.
    func open(_ url: URL)
    /// The state a reply's UI was left in, such as a form's values.
    func state(for messageID: String) -> RawJSON?
    /// Keeps the state a reply's UI was left in.
    func setState(_ state: RawJSON?, for messageID: String)
}

@available(iOS 15.0, macOS 12.0, *)
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
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class AIUIHost<Renderers: AIUIRendererList>: AIUIHosting, ObservableObject {
    /// The renderers of the formats it reads, the first one listed asked first.
    public let renderers: Renderers
    public let components: [any AIUIComponent]

    private let tools: [String: any AIClientTool]
    private let sendAction: @MainActor (AIUIAction) async throws -> Void
    private let openLink: @MainActor (URL) -> Void
    private let engines = AIUIEngines()
    private var states: [String: RawJSON] = [:]
    private var received: [String: AIUIDocument] = [:]
    private var lastSend: Task<Void, Never>?

    /// - Parameters:
    ///   - components: The app's views the agent can place.
    ///   - tools: The app's tools a reply's UI can run on this device, which the agent's
    ///     instructions list. They run without asking the person. One whose definition says it
    ///     is read-only (`readOnlyHint`) runs whenever the UI asks, such as to load data while it
    ///     shows; any other only when the person taps something that runs it. They are apart from
    ///     the tools the agent calls.
    ///   - renderers: The renderer of each format the agent writes.
    ///   - send: Sends what the person did to the agent, as their next message.
    ///   - open: Opens a link from a reply's UI, such as with SwiftUI's `openURL`. By default, web
    ///     and email links open and others don't: the agent writes the links, so another could
    ///     call someone or act in another app.
    public init(
        components: [any AIUIComponent] = [],
        tools: [any AIClientTool] = [],
        @AIUIRendererListBuilder renderers: () -> Renderers,
        send: @escaping @MainActor (AIUIAction) async throws -> Void,
        open: (@MainActor (URL) -> Void)? = nil
    ) {
        self.renderers = renderers()
        self.components = components
        self.tools = Dictionary(tools.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        sendAction = send
        openLink = open ?? AIUILinks.openIfWebOrEmail
    }

    /// Whether one of its renderers reads `document`. The one that does can still show nothing
    /// of its own for a reply, which then shows its text, as ``AIUIView/canShow`` tells.
    public func canShow(_ document: AIUIDocument) -> Bool {
        renderers.reads(document)
    }

    /// Sends what the person did to the agent, after everything sent before it, so the agent gets
    /// a reply's actions in the order they happened.
    public func send(_ action: AIUIAction) {
        let previous = lastSend
        lastSend = Task { @MainActor in
            await previous?.value
            do {
                try await sendAction(action)
            } catch {
                log.error("Couldn't send what the person did in a reply's UI", error: error)
            }
        }
    }

    public func runTool(
        _ name: String,
        arguments: [String: RawJSON] = [:],
        userInitiated: Bool = false
    ) async throws -> RawJSON {
        guard let tool = tools[name] else {
            throw AIUIToolError(message: "No tool named \(name)")
        }
        guard userInitiated || tool.definition.isReadOnly else {
            throw AIUIToolError(message: "\(name) isn't read-only, so it runs only when the person asks for it")
        }
        let call = AIToolCallPart(
            id: UUID().uuidString,
            name: name,
            status: .awaitingClient,
            executor: .client,
            arguments: try JSONEncoder.streamCore.encode(arguments)
        )
        let result = await tool.run(call)
        if let failure = result.failure {
            throw AIUIToolError(message: failure)
        }
        guard let output = result.output else { return .nil }
        return try JSONDecoder.streamCore.decode(RawJSON.self, from: output)
    }

    public func open(_ url: URL) {
        openLink(url)
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
    /// earlier one's UI follows them all. It also tells them when a reply leaves the
    /// conversation, or its UI does, such as when it is deleted. ``AIConversationView`` does it:
    /// call it with the conversation's messages when you show replies yourself with ``AIUIView``.
    public func receive<Message: AIMessage>(_ messages: [Message]) {
        let documents = messages.compactMap { message -> (String, AIUIDocument)? in
            guard message.role != .user, let document = message.uiDocument else { return nil }
            return (String(describing: message.id), document)
        }
        let current = Set(documents.map { $0.0 })
        for (messageID, document) in received where !current.contains(messageID) {
            received[messageID] = nil
            states[messageID] = nil
            renderers.remove(document, messageID: messageID, in: context)
        }
        for (messageID, document) in documents where received[messageID] != document {
            received[messageID] = document
            renderers.receive(document, messageID: messageID, in: context)
        }
    }

    // The app's tools a reply's UI can run, in a steady order for the agent's instructions.
    private var toolDefinitions: [AIClientToolDefinition] {
        tools.values.map(\.definition).sorted { $0.name < $1.name }
    }

    /// What the agent's backend needs to write UI this app shows: each format it reads, with
    /// what its renderer adds, such as the instructions that list the app's tools, and the app's
    /// components.
    public var capabilities: [String: RawJSON] {
        let formats = renderers.all.map { renderer -> RawJSON in
            var fields = renderer.capabilities(components: components, tools: toolDefinitions)
            fields["format"] = .string(renderer.format.rawValue)
            return .dictionary(fields)
        }
        let definitions = components.compactMap { component -> RawJSON? in
            do {
                return try JSONDecoder.streamCore.decode(RawJSON.self, from: JSONEncoder.streamCore.encode(component.definition))
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

// What tells whether a reply's UI shows, such as a conversation's host.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
protocol AIUIDocumentReader {
    func canShow(_ document: AIUIDocument) -> Bool
}

@available(iOS 15.0, macOS 12.0, *)
extension AIUIHost: AIUIDocumentReader {}

// The links a reply's UI opens unless the app opens them itself.
@available(iOS 15.0, macOS 12.0, *)
enum AIUILinks {
    static let schemes: Set<String> = ["http", "https", "mailto"]

    static func isWebOrEmail(_ url: URL) -> Bool {
        schemes.contains(url.scheme?.lowercased() ?? "")
    }

    @MainActor
    static func openIfWebOrEmail(_ url: URL) {
        guard isWebOrEmail(url) else {
            log.warning("A reply's UI asked to open \(url), which isn't a web or email link")
            return
        }
        UIApplication.shared.open(url)
    }
}

@available(iOS 15.0, macOS 12.0, *)
struct AIUIToolError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
