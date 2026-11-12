//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// What an agent is told so that its model writes replies' UI in A2UI: how a reply carries the
/// UI, the protocol, the catalog it writes with, the app's own components, and examples.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIInstructions {
    /// The catalog the model writes with, the app's components among its own.
    var catalog: Catalog
    /// The info string of the fenced block a reply's UI is written in.
    var fence: String
    /// What the model is told first, such as which answers to write as UI.
    var preamble: String?
    /// Guidance on using the app's components.
    var notes: [String]
    /// The app's tools the UI can call, each a line of Markdown.
    var tools: [String]
    /// Rules added after the protocol's.
    var rules: [String]
    /// Examples of replies with their UI.
    var examples: [String]

    init(
        catalog: Catalog,
        fence: String,
        preamble: String? = nil,
        notes: [String] = [],
        tools: [String] = [],
        rules: [String] = [],
        examples: [String] = []
    ) {
        self.catalog = catalog
        self.fence = fence
        self.preamble = preamble
        self.notes = notes
        self.tools = tools
        self.rules = rules
        self.examples = examples
    }

    /// The instructions, in Markdown.
    var text: String {
        var sections: [String] = []
        if let preamble, !preamble.isEmpty {
            sections.append(preamble)
        }
        sections.append(writing)
        sections.append(A2UIPromptBuilder.protocolOverview)
        if let guidelines = catalog.instructions, !guidelines.isEmpty {
            sections.append(guidelines)
        }
        if !notes.isEmpty {
            sections.append("## The app's components\n\n" + notes.joined(separator: "\n"))
        }
        if !tools.isEmpty {
            sections.append(Self.toolsIntroduction + "\n\n" + tools.joined(separator: "\n"))
        }
        sections.append("## The catalog `\(catalog.catalogId)`\n\n```json\n\(document)\n```")
        if !rules.isEmpty {
            let numbered = rules.enumerated().map { "\($0.offset + 1). \($0.element)" }
            sections.append("## Rules\n\n" + numbered.joined(separator: "\n"))
        }
        if !examples.isEmpty {
            sections.append("## Examples\n\n" + examples.joined(separator: "\n\n"))
        }
        return sections.joined(separator: "\n\n")
    }

    private var writing: String {
        """
        ## Writing UI in A2UI

        Write a reply's UI in one fenced block whose info string is `\(fence)`, after one short \
        sentence saying what it shows, which is what people read wherever the UI can't show. In the \
        block, write A2UI messages, one JSON object per line, and nothing else:

        1. First a `createSurface` with a `surfaceId` new to this reply, the `catalogId` \
        `\(catalog.catalogId)`, and the `dataModel` the UI's inputs start from.
        2. Then `updateComponents` messages for that surface with a few components each, `root` \
        first, so the UI shows as you write it.

        A reply's UI is shown as you wrote it: never write `callRendererFunction` or \
        `agentFunctionResponse`, and never change an earlier reply's UI, but write a new one. What \
        the person does in it comes back as their next message, which says what the button they \
        tapped says. Give every event action a `userMessage` saying what it asks of you, such as \
        "Update the plan", which comes back with it, and a `context` with what you need to know, \
        bound to the data model.
        """
    }

    private static let toolsIntroduction = """
    ## The app's tools

    These run on the person's device. Call one as you call a function the catalog doesn't \
    define, with `{"@call": "<name>", "args": {…}}`, and its output is the call's value. A \
    read-only tool runs wherever you call it, such as in a binding that shows its output. Any \
    other runs only from a button's `functionCall` action, when the person taps it.
    """

    // The catalog as one line of JSON, its keys sorted so the same catalog always reads the same.
    // Its guidelines are a section of their own.
    private var document: String {
        var schema = catalog.toJsonSchema()
        schema["instructions"] = nil
        let options: JSONSerialization.WritingOptions = [.sortedKeys, .withoutEscapingSlashes]
        // JSONSerialization raises an exception `try` can't catch for a value JSON can't hold.
        guard JSONSerialization.isValidJSONObject(schema),
              let data = try? JSONSerialization.data(withJSONObject: schema, options: options) else {
            return "{}"
        }
        return String(decoding: data, as: UTF8.self)
    }
}
