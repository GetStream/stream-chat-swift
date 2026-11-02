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
/// submit button, reaches the host as an `AIUIAction` named after OpenUI's action, with the
/// form's values in its payload. Links open through the host.
@available(iOS 17.0, macOS 14.0, *)
@MainActor
public final class OpenUIRenderer: AIUIRenderer {
    public let format: AIUIFormat = .openUI
    /// The library the agent writes with, before the app's components join it.
    public let library: ComponentLibrary
    private let toolProvider: (any OpenUIToolProvider)?

    /// - Parameters:
    ///   - library: The library the agent writes with, the chat library by default.
    ///   - toolProvider: Runs the tools of `Query()` and `Mutation()`. By default they are the
    ///     host's tools, run on the device.
    public init(library: ComponentLibrary = .openUIChat, toolProvider: (any OpenUIToolProvider)? = nil) {
        self.library = library
        self.toolProvider = toolProvider
    }

    /// The fence the agent writes its program in, and the instructions its model needs to write
    /// one with the app's components.
    public func capabilities(components: [any AIUIComponent]) -> [String: RawJSON] {
        let definitions = Self.placeableSchemas(of: components, in: library).map { ComponentDefinition($0.schema, renderer: nil) }
        let library = library.addingContent(definitions)
        return ["fence": .string("openui-lang"), "instructions": .string(library.systemPrompt())]
    }

    public func makeEngine(host: any AIUIHosting) -> some AIUIEngine {
        OpenUIEngine(library: library, host: host, toolProvider: toolProvider ?? HostToolProvider(host: host))
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
