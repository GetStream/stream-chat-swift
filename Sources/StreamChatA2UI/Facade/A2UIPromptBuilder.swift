//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Builds the prompt an LLM needs in order to generate A2UI v1.0 messages.
///
/// Use this when an agent drives a model directly instead of relying on an
/// A2UI SDK: the prompt describes the message envelope, embeds the catalogs the
/// renderer supports, and states the rules that keep generated trees valid.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIPromptBuilder {
    /// Builds a system prompt for the given catalogs.
    ///
    /// - Parameters:
    ///   - catalogs: The catalogs the renderer supports.
    ///   - includeCatalogSchemas: Whether to embed the full catalog documents.
    ///     Turn this off when the model already has them.
    static func systemPrompt(catalogs: [Catalog], includeCatalogSchemas: Bool = true) -> String {
        var sections = [protocolOverview]

        let instructions = catalogs.compactMap { catalog -> String? in
            guard let instructions = catalog.instructions else { return nil }
            return "## Guidelines for catalog `\(catalog.catalogId)`\n\n\(instructions)"
        }
        sections.append(contentsOf: instructions)

        if includeCatalogSchemas {
            for catalog in catalogs {
                sections.append(
                    """
                    ## Catalog `\(catalog.catalogId)`

                    ```json
                    \(catalogDocument(catalog))
                    ```
                    """
                )
            }
        }
        return sections.joined(separator: "\n\n")
    }

    /// Serializes a catalog as an A2UI v1.0 catalog definition document.
    /// Embed this in a prompt or send it as an inline catalog.
    static func catalogDocument(_ catalog: Catalog) -> String {
        Json.encodeToString(catalog.toJsonSchema(), pretty: true) ?? "{}"
    }

    /// A description of the A2UI v1.0 message envelope and its rules.
    static let protocolOverview = """
    # Generating user interfaces with A2UI v1.0

    You render user interfaces by emitting A2UI messages. Every message is a JSON object with a \
    `"version": "1.0"` field plus exactly one of these keys:

    - `createSurface`: creates a surface. Requires `surfaceId`, and accepts `catalogId`, `sendDataModel`, \
    `components` and `dataModel` so a complete UI can be sent in one message.
    - `updateComponents`: adds or replaces components of an existing surface. Requires `surfaceId` and \
    `components`.
    - `updateDataModel`: writes to the surface data model. Requires `surfaceId` and `value`, and accepts a \
    JSON Pointer `path`. Setting `value` to `null` deletes the entry at `path`.
    - `deleteSurface`: removes a surface. Requires `surfaceId`.
    - `callRendererFunction`: asks the renderer to run one of its functions.
    - `agentFunctionResponse`: answers a `callAgentFunction` request from the renderer.

    Rules:

    1. Components are a flat adjacency list. Each component has a unique `id`, a `component` type, and its \
    properties inline. Exactly one component must have the id `root`. An id is an identifier: letters, \
    digits and underscores, not starting with a digit, such as `saturday_plan` (never `saturday-plan`).
    2. Children are referenced by id, never nested inline. Use an array of ids, or \
    `{"componentId": "...", "path": "/items"}` to repeat a template for every item of a data model list.
    3. Any property may be a literal, a data binding `{"@path": "/a/b"}` or a function call \
    `{"@call": "name", "args": {...}}`. Inside a list template, paths without a leading slash resolve \
    relative to the current item, and `{"@call": "@index"}` returns the item's position. A literal \
    object key that starts with `@` is written with `@@`, so `"@@type"` means `"@type"`.
    4. Put content that changes in the data model and bind to it, so you can update values with \
    `updateDataModel` instead of resending components.
    5. Interactive components declare an `action`, which either dispatches an event to you \
    (`{"event": {"name": "...", "context": {...}}}`) or runs a renderer function \
    (`{"functionCall": {"@call": "openUrl", "args": {"url": "..."}}}`).
    6. Surface ids must be unique for the lifetime of the renderer. Creating a surface that already exists \
    is an error: delete it first, or send `updateComponents` and `updateDataModel` to change it.
    """
}
