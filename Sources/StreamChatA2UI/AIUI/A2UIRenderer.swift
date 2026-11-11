//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatAI
import SwiftUI

/// Shows the replies an agent writes in A2UI 1.0, with the basic catalog and the app's
/// components beside the catalog's own.
///
/// ```swift
/// let ui = AIUIHost(components: [PlaceCardComponent()]) {
///     A2UIRenderer()
/// } send: { action in
///     try await chat.sendMessage(with: action.label, extraData: action.customData)
/// }
/// ```
///
/// Each reply keeps its own surfaces, so what the person enters in them survives scrolling. A
/// button's event reaches the host as an ``AIUIAction`` named after it, labeled with the button's
/// text, and with its surface, its component, its resolved `context` and the agent's
/// `userMessage` in the payload, with the surface's data model too when the agent asks for it
/// with `sendDataModel`. The label is never the agent's words, which could say something the
/// person didn't choose. A function the catalog doesn't define runs as one of the host's tools, and
/// links open through the host.
///
/// An app component named like one of the catalog's, such as `card` for `Card`, would replace
/// it, so the agent doesn't get it and it is logged.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public final class A2UIRenderer: AIUIRenderer {
    /// The version of A2UI it reads.
    public static let version = A2UIProtocol.version

    /// The catalog id the agent names the catalog with the app's components by, unless it is
    /// given another.
    public static let defaultCatalogId = "getstream.io:app-catalog"

    public let format: AIUIFormat = .a2ui

    /// The catalog the agent writes with, before the app's components join it.
    public let catalog: Catalog

    /// The id of the catalog with the app's components.
    public let catalogId: String

    let instructions: String?
    let theme: A2UITheme?
    let mediaURL: @Sendable (URL) -> URL?
    let onError: (@MainActor (A2UIError, _ messageID: String) -> Void)?

    /// - Parameters:
    ///   - catalog: The catalog the agent writes with, the basic catalog by default.
    ///   - catalogId: The id the agent names the catalog with the app's components by.
    ///   - instructions: What the agent's model is told before A2UI's own instructions, such as
    ///     which answers to write as UI and when to use the app's components.
    ///   - theme: The look of the replies' A2UI. By default it follows the conversation's
    ///     `AIAppearance`, ``A2UITheme/init(appearance:)``.
    ///   - mediaURL: The URL an image, video or audio clip loads from, given the one the agent
    ///     wrote, or `nil` to not load it. By default only web links load, ``webURL(_:)``.
    ///   - onError: Gets the problems with a reply's A2UI, which A2UI reports to the agent, such
    ///     as a message that doesn't read. A chat has no channel for them, so forward them to
    ///     your backend if the agent should hear about them. They are logged by default.
    public init(
        catalog: Catalog = BasicCatalog.catalog,
        catalogId: String = A2UIRenderer.defaultCatalogId,
        instructions: String? = nil,
        theme: A2UITheme? = nil,
        mediaURL: @escaping @Sendable (URL) -> URL? = { A2UIRenderer.webURL($0) },
        onError: (@MainActor (A2UIError, _ messageID: String) -> Void)? = nil
    ) {
        self.catalog = catalog
        self.catalogId = catalogId
        self.instructions = instructions
        self.theme = theme
        self.mediaURL = mediaURL
        self.onError = onError
        a2uiLogger.handler = Self.forwardToStreamCore
    }

    /// `url` when it is an http or https link, and `nil` otherwise: the agent writes the links a
    /// reply's media load from.
    public nonisolated static func webURL(_ url: URL) -> URL? {
        ["http", "https"].contains(url.scheme?.lowercased() ?? "") ? url : nil
    }

    /// The info string of the fenced block the agent writes a reply's UI in.
    public var fence: String { "ui:a2ui@\(Self.version)" }

    public func supports(version: String?) -> Bool {
        guard let version else { return true }
        return version == Self.version || A2UIReply.versionSpellings.contains(version)
    }

    /// The fence the agent writes its UI in, the catalog's id, and the instructions its model
    /// needs to write UI with the app's components and call the app's tools.
    public func capabilities(components: [any AIUIComponent], tools: [AIClientToolDefinition]) -> [String: RawJSON] {
        let appComponents = definitions(of: components) { _ in { _ in AnyView(EmptyView()) } }
        let prompt = A2UIInstructions(
            catalog: catalogs(adding: appComponents)[0],
            fence: fence,
            preamble: instructions,
            tools: tools.map { Self.line(for: $0) }
        )
        return [
            "fence": .string(fence),
            "catalog_id": .string(catalogId),
            "instructions": .string(prompt.text)
        ]
    }

    public func makeEngine(host: any AIUIHosting) -> some AIUIEngine {
        A2UIEngine(renderer: self, host: host)
    }

    /// The catalog with `components`, under its own id and under the id of the catalog it
    /// extends, so a surface naming either one shows the app's components. With `entrances`, the
    /// catalog's own components come in as they show, as the app's do.
    func catalogs(adding components: [ComponentDefinition], entrances: Bool = false) -> [Catalog] {
        let catalog = entrances ? catalog.withEntrances : catalog
        let extended = catalog.adding(components: components, catalogId: catalogId)
        guard catalog.catalogId != catalogId else { return [extended] }
        return [extended, catalog.adding(components: components)]
    }

    /// The A2UI components of the app's that the agent can place, each shown by its `builder`.
    /// One named like a component of the catalog would replace it, so it is left out, as is one
    /// A2UI can't describe.
    func definitions(
        of components: [any AIUIComponent],
        builder: (any AIUIComponent) -> ComponentViewBuilder
    ) -> [ComponentDefinition] {
        components.compactMap { component in
            let definition: ComponentDefinition
            do {
                definition = try Self.definition(of: component.definition, builder: builder(component))
            } catch {
                log.error("A2UI leaves out the app's component \(component.name), which it can't describe", error: error)
                return nil
            }
            guard catalog.component(definition.name) == nil else {
                log.error(
                    "A2UI leaves out the app's component \(component.name), which would replace the catalog's \(definition.name)"
                )
                return nil
            }
            return definition
        }
    }

    // A tool as the agent's instructions list it: its name, whether it only reads, what it does,
    // and the schema of its arguments.
    static func line(for tool: AIClientToolDefinition) -> String {
        var line = "- `\(tool.name)`"
        if tool.isReadOnly {
            line += " (read-only)"
        }
        if let description = tool.description, !description.isEmpty {
            line += ": \(description)"
        }
        if let schema = tool.inputSchema, let text = Self.text(of: schema) {
            line += " Arguments: `\(text)`"
        }
        return line
    }

    private static func text(of json: RawJSON) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return (try? encoder.encode(json)).map { String(decoding: $0, as: UTF8.self) }
    }

    /// The A2UI component for one of the app's, described the same way on every platform.
    static func definition(
        of definition: AIUIComponentDefinition,
        builder: @escaping ComponentViewBuilder
    ) throws -> ComponentDefinition {
        let data = try JSONEncoder().encode(definition)
        guard let portable = Json.decodeMap(data) else {
            throw PortableComponentError(message: "\(definition.name) has no definition A2UI can read")
        }
        return try PortableComponent.definition(portable, builder: builder)
    }

    // The renderer's own messages go to StreamCore's logger, with the rest of the SDK's.
    private nonisolated static func forwardToStreamCore(_ level: A2UILogLevel, _ message: String) {
        switch level {
        case .debug: log.debug(message)
        case .info: log.info(message)
        case .warning: log.warning(message)
        case .error: log.error(message)
        }
    }
}
