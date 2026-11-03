//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatAI
import SwiftUI

/// Shows the replies an agent writes in OpenUI Lang in StreamChatAI's generative UI, with the
/// app's components placeable wherever OpenUI's own content goes.
///
/// ```swift
/// let ui = AIUIHost(components: [PlaceCardComponent()]) {
///     OpenUIRenderer()
/// } send: { action in
///     try await chat.sendMessage(with: action.label, extraData: action.customData)
/// }
/// ```
///
/// Each reply keeps its own runtime, so its forms and the state of its `$variables` survive
/// scrolling. What the person does that is for the agent, such as a follow-up or a form's
/// submit button, reaches the host as an `AIUIAction` named after OpenUI's action, labeled with
/// the control they tapped, with the form's values in its payload. A `Query` runs one of the
/// host's read-only tools as the reply shows; a `Mutation` runs any of them, when the person
/// taps. Links open through the host.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class OpenUIRenderer: AIUIRenderer {
    public let format: AIUIFormat = .openUI
    /// The library the agent writes with, before the app's components join it.
    public let library: ComponentLibrary
    private let instructions: String?
    let theme: OpenUITheme?
    private let mediaURL: @Sendable (URL) -> URL?
    private let onError: (@MainActor (OpenUIError, _ messageID: String) -> Void)?

    /// - Parameters:
    ///   - library: The library the agent writes with, the chat library by default.
    ///   - instructions: What the agent's model is told before OpenUI's own instructions, such as
    ///     which answers to write as UI and when to use the app's components.
    ///   - theme: The look of the replies' OpenUI. By default it follows the conversation's
    ///     `AIAppearance`, ``OpenUITheme/init(appearance:)``.
    ///   - mediaURL: The URL an image loads from, given the web link the model wrote, or `nil` to
    ///     not load it, such as to allow only your own image hosts. It gets only links the model
    ///     wrote out or a tool returned, so one built from what the person typed never loads. By
    ///     default each of those loads.
    ///   - onError: Gets the problems with a reply's program once it is complete, such as a
    ///     component it doesn't know or a tool that failed. A chat has no channel for them, so
    ///     forward them to your backend if the agent should hear about them. They are logged by
    ///     default.
    public init(
        library: ComponentLibrary = .openUIChat,
        instructions: String? = nil,
        theme: OpenUITheme? = nil,
        mediaURL: @escaping @Sendable (URL) -> URL? = { $0 },
        onError: (@MainActor (OpenUIError, _ messageID: String) -> Void)? = nil
    ) {
        self.library = library
        self.instructions = instructions
        self.theme = theme
        self.mediaURL = mediaURL
        self.onError = onError
    }

    /// The fence the agent writes its program in, and the instructions its model needs to write
    /// one with the app's components and run the app's tools.
    public func capabilities(components: [any AIUIComponent], tools: [AIClientToolDefinition]) -> [String: RawJSON] {
        let definitions = Self.placeableSchemas(of: components, in: library).map { OpenUIComponentDefinition($0.schema, renderer: nil) }
        let library = library.addingContent(definitions)
        var options = library.defaultPromptOptions
        options.tools += tools.map { .spec(Self.spec(of: $0)) }
        let prompt = [instructions, library.systemPrompt(options)].compactMap { $0?.isEmpty == false ? $0 : nil }
        return ["fence": .string("openui-lang"), "instructions": .string(prompt.joined(separator: "\n\n"))]
    }

    public func makeEngine(host: any AIUIHosting) -> some AIUIEngine {
        OpenUIEngine(
            library: library,
            host: host,
            toolProvider: HostToolProvider(host: host),
            mediaURL: mediaURL,
            theme: theme,
            onError: onError
        )
    }

    // One of the host's tools as the model's instructions list it, saying whether a `Query` can
    // run it.
    static func spec(of tool: AIClientToolDefinition) -> ToolSpec {
        let use = tool.isReadOnly
            ? "Read-only: use it in Query() or Mutation()."
            : "It changes something: use it only in Mutation(), which runs when the person taps."
        let description = [tool.description, use].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " ")
        return ToolSpec(name: tool.name, description: description, inputSchema: tool.inputSchema?.openUIValue ?? [:])
    }

    static func schema(of definition: AIUIComponentDefinition) throws -> ComponentSchema {
        try ComponentSchema(portableDefinition: OpenUIJSON.parse(JSONEncoder().encode(definition)))
    }

    // The app's components the agent can place with `library`, each with its OpenUI schema. One
    // whose definition can't be read, or whose OpenUI name the library already has, is left out
    // of both the instructions and the engine, so it never replaces one of OpenUI's own.
    static func placeableSchemas(
        of components: [any AIUIComponent],
        in library: ComponentLibrary
    ) -> [(component: any AIUIComponent, schema: ComponentSchema)] {
        var names = Set(library.componentNames)
        return components.compactMap { component in
            let schema: ComponentSchema
            do {
                schema = try Self.schema(of: component.definition)
            } catch {
                log.error("Couldn't read the component \(component.name) for OpenUI", error: error)
                return nil
            }
            guard names.insert(schema.name).inserted else {
                log.error("The component \(component.name) is left out of OpenUI: its name \(schema.name) is taken")
                return nil
            }
            return (component, schema)
        }
    }
}
