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
/// button's event reaches the host as an ``AIUIAction`` named after it, with the person's words,
/// its `userMessage`, as the label, and its surface, its component and its resolved `context` in
/// the payload. Links open through the host.
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

    let mediaURL: @Sendable (URL) -> URL?
    let onError: (@MainActor (A2UIError, _ messageID: String) -> Void)?

    /// - Parameters:
    ///   - catalog: The catalog the agent writes with, the basic catalog by default.
    ///   - catalogId: The id the agent names the catalog with the app's components by.
    ///   - mediaURL: The URL an image, video or audio clip loads from, given the one the agent
    ///     wrote, or `nil` to not load it. By default only web links load, ``webURL(_:)``.
    ///   - onError: Gets the problems with a reply's A2UI, which A2UI reports to the agent, such
    ///     as a message that doesn't read. A chat has no channel for them, so forward them to
    ///     your backend if the agent should hear about them. They are logged by default.
    public init(
        catalog: Catalog = BasicCatalog.catalog,
        catalogId: String = A2UIRenderer.defaultCatalogId,
        mediaURL: @escaping @Sendable (URL) -> URL? = { A2UIRenderer.webURL($0) },
        onError: (@MainActor (A2UIError, _ messageID: String) -> Void)? = nil
    ) {
        self.catalog = catalog
        self.catalogId = catalogId
        self.mediaURL = mediaURL
        self.onError = onError
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
        return Self.supportedVersions.contains(version)
    }

    /// The fence the agent writes its UI in, the catalog's id, and the instructions its model
    /// needs to write UI with the app's components.
    public func capabilities(components: [any AIUIComponent]) -> [String: RawJSON] {
        let definitions = components.compactMap { component in
            try? Self.definition(of: component.definition) { _ in AnyView(EmptyView()) }
        }
        let instructions = A2UIInstructions(catalog: catalogs(adding: definitions)[0], fence: fence)
        return [
            "fence": .string(fence),
            "catalog_id": .string(catalogId),
            "instructions": .string(instructions.text)
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

    // The document versions it reads. The pre-release spellings come from agents prompted before
    // the 1.0 release.
    private static let supportedVersions: Set<String> = ["1", "1.0", "1.0.0", "v1.0"]
}
