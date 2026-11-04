//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

/// The conformance test library (`spec/fixtures/1.0/library.json`) defined with the Swift API.
enum SpecLibrary {
    static let upper = OpenUIFunction("Upper", description: "The text in upper case", params: [.required("text", .string)], returns: .string) { args in
        .string((args["text"]?.stringValue ?? "").uppercased())
    }

    static let copyToClipboard = OpenUICustomAction("CopyToClipboard", description: "Copies text to the clipboard", params: [.required("text", .string)])

    static let library = ComponentLibrary(
        root: "Stack",
        components: [
            schema("Stack", "Lays out children in a column or a row", [.required("children", .array(.any)), .optional("direction", .enumeration(["row", "column"]))]),
            schema("Card", "A titled container", [.required("title", .string), .optional("children", .array(.any))]),
            schema("Text", "A run of text", [.required("text", .string), .optional("variant", .enumeration(["body", "heading"]))]),
            schema("Tag", "A small colored label", [.required("text", .string), .optional("color", .enumeration(["gray", "green", "red"]))]),
            schema("Metric", "A labeled number", [.required("label", .string), .required("value", .number)]),
            schema("Button", "A clickable button", [
                .required("label", .string),
                .optional("action", .action),
                .optional("variant", .enumeration(["primary", "secondary"])),
                .optional("share", .actions(["CopyToClipboard", "OpenUrl"]))
            ]),
            schema("Form", "Groups its inputs under a form name", [.required("name", .string), .required("children", .array(.any))]),
            schema("Input", "A text field", [.required("name", .string), .optional("placeholder", .string), .binding("value", .string), .optional("rules", .object([]))]),
            schema("Select", "A dropdown", [.required("name", .string), .required("items", .array(.any)), .binding("value", .string)]),
            schema("SelectItem", "One option of a Select", [.required("value", .string), .required("label", .string)]),
            schema("Table", "A table built from columns", [.required("columns", .array(.any))]),
            schema("Col", "One table column: a header and its cell values", [.required("label", .string), .optional("data", .array(.any))])
        ],
        functions: [upper],
        customActions: [copyToClipboard]
    )

    static func schema(_ name: String, _ description: String, _ props: [PropField]) -> OpenUIComponentDefinition {
        OpenUIComponentDefinition(ComponentSchema(name, description: description, props: props), renderer: nil)
    }
}

@Suite("Library API")
struct LibraryAPITests {
    // MARK: - Prop types

    @Test func propTypesCompareByValue() {
        #expect(PropType.array(.string) == .array(.string))
        #expect(PropType.array(.string) != .array(.string, minItems: 1))
        #expect(PropType.union([.component("A"), .component("B")]) == .union([.component("A"), .component("B")]))
        #expect(PropType.enumeration(["a"]) != .literal("a"))
        #expect(PropType.actions(["OpenUrl"]) != .action)
    }

    @Test func propTypeSignatures() {
        #expect(PropType.array(.union([.component("A"), .component("B")])).signature == "(A | B)[]")
        #expect(PropType.record(.number).signature == "Record<string, number>")
        #expect(PropType.object([.required("a", .string), .optional("b", .number)]).signature == "{a: string, b?: number}")
        #expect(PropType.action.signature == "ActionExpression")
        #expect(PropType.actions(["CopyToClipboard", "OpenUrl"]).signature == "@CopyToClipboard | @OpenUrl")
    }

    @Test func actionPropsReferToActionDefinitions() {
        #expect(PropType.action.jsonSchema == ["$ref": "#/$defs/ActionExpression"])
        #expect(PropType.actions(["CopyToClipboard", "OpenUrl"]).jsonSchema == [
            "anyOf": [["$ref": "#/$defs/CopyToClipboard"], ["$ref": "#/$defs/OpenUrl"]]
        ])
    }

    // MARK: - Functions and actions

    @Test func functionAndActionSignatures() {
        #expect(SpecLibrary.upper.signature == "Upper(text: string) → string")
        #expect(SpecLibrary.copyToClipboard.signature == "CopyToClipboard(text: string)")
    }

    @Test func libraryJSONHoldsActionDefinitionsWhereTheyAreFirstUsed() throws {
        let defs = try #require(SpecLibrary.library.jsonSchema["$defs"]?.objectValue)

        #expect(Array(defs.keys.prefix(9)) == ["Stack", "Card", "Text", "Tag", "Metric", "Button", "ActionExpression", "CopyToClipboard", "OpenUrl"])
        #expect(defs["ActionExpression"] == PropType.actionSchema)
        #expect(defs["OpenUrl"] == PropType.openURLSchema)
        #expect(defs["CopyToClipboard"] == [
            "type": "object",
            "properties": [
                "type": ["type": "string", "const": "CopyToClipboard"],
                "params": ["type": "object", "properties": ["text": ["type": "string"]], "required": ["text"], "additionalProperties": false]
            ],
            "required": ["type", "params"],
            "additionalProperties": false
        ])
        #expect(defs["ToAssistant"] == nil, "only the definitions a slot uses are listed")
    }

    @Test func libraryJSONListsFunctionsAndActions() throws {
        let schema = SpecLibrary.library.jsonSchema

        #expect(schema["functions"]?["Upper"] == [
            "description": "The text in upper case",
            "params": ["type": "object", "properties": ["text": ["type": "string"]], "required": ["text"], "additionalProperties": false],
            "returns": ["type": "string"]
        ])
        #expect(schema["actions"]?["CopyToClipboard"]?["description"] == "Copies text to the clipboard")
        #expect(schema["actions"]?["CopyToClipboard"]?["returns"] == nil)
        #expect(ComponentLibrary.openUIChat.jsonSchema["functions"] == nil)
    }

    @Test func specJSONDescribesFunctionsAndActions() {
        let spec = SpecLibrary.library.specJSON

        #expect(spec["functions"] == ["Upper": ["signature": "Upper(text: string) → string", "description": "The text in upper case"]])
        #expect(spec["actions"] == ["CopyToClipboard": ["signature": "CopyToClipboard(text: string)", "description": "Copies text to the clipboard"]])
        #expect(spec["componentGroups"] == nil, "a library without groups leaves them out, as upstream does")
    }

    @Test func libraryActionsAndRestrictedSlotsParse() {
        let result = SpecLibrary.library.parser.parse("""
        root = Stack([copy, share])
        copy = Button("Copy", @CopyToClipboard("abc"))
        share = Button("Share", null, "primary", @OpenUrl("https://getstream.io"))
        """)

        #expect(result.meta.errors.isEmpty)
        #expect(result.root?.props["children"]?.arrayValue?.count == 2)
    }

    // MARK: - Removing

    @Test func removingStripsComponentsFromSlotsAndGroups() throws {
        let library = ComponentLibrary.openUIChat.removing(["Table", "Col", "EditableTable"])

        #expect(library.component(named: "Table") == nil)
        #expect(library.componentGroups.contains { $0.name == "Tables" } == false)
        let card = try #require(library.component(named: "Card"))
        #expect(card.schema.signature.contains("Table") == false)
        #expect(OpenUIJSON.stringify(library.jsonSchema).contains("#/$defs/Table\"") == false)
        #expect(library.systemPrompt().contains("### Tables") == false)
    }

    @Test func removingKeepsTheRootAndASlotsOnlyType() {
        let library = ComponentLibrary.openUIChat.removing(["Card", "FollowUpItem", "Callout"])

        #expect(library.root == "Card")
        #expect(library.component(named: "Card") != nil)
        #expect(library.component(named: "FollowUpItem") != nil, "FollowUpBlock takes only FollowUpItem")
        #expect(library.component(named: "Callout") == nil)
    }

    // MARK: - Adding

    @Test func addingKeepsTheLibrarysOwnComponentsAndSkipsUncallableNames() throws {
        let replacement = OpenUIComponentDefinition(ComponentSchema("Card", description: "Not the chat card", props: [.required("x", .string)]), renderer: nil)
        let lowercase = OpenUIComponentDefinition(ComponentSchema("placeCard", description: "", props: []), renderer: nil)
        let builtin = OpenUIComponentDefinition(ComponentSchema("Each", description: "", props: []), renderer: nil)
        let valid = OpenUIComponentDefinition(ComponentSchema("PlaceCard", description: "A place", props: [.required("title", .string)]), renderer: nil)

        let added = ComponentLibrary.openUIChat.adding([replacement, lowercase, builtin, valid])
        let content = ComponentLibrary.openUIChat.addingContent([replacement, lowercase, builtin, valid])

        for library in [added, content] {
            #expect(library.component(named: "Card")?.schema.description == ComponentLibrary.openUIChat.component(named: "Card")?.schema.description)
            #expect(library.component(named: "Card")?.schema.props.contains { $0.name == "x" } == false)
            #expect(library.component(named: "placeCard") == nil)
            #expect(library.component(named: "Each") == nil)
            #expect(library.component(named: "PlaceCard") != nil)
        }
        #expect(content.componentGroups.last?.components == ["PlaceCard"])
        let card = try #require(content.component(named: "Card"))
        #expect(card.schema.signature.contains("PlaceCard"))
    }

    @Test func addingContentWithNothingAddableLeavesTheLibrary() {
        let library = ComponentLibrary.openUIChat.addingContent([])

        #expect(library.componentGroups.count == ComponentLibrary.openUIChat.componentGroups.count)
    }

    // MARK: - Prompt

    @Test func customFunctionsAndActionsGetTheirOwnSectionsWithoutBuiltIns() {
        let library = ComponentLibrary(
            root: "Box",
            components: [SpecLibrary.schema("Box", "A box", [.required("text", .string)])],
            functions: [SpecLibrary.upper],
            customActions: [SpecLibrary.copyToClipboard]
        )

        let prompt = library.systemPrompt()

        #expect(prompt.contains("## Built-in Functions\n\n@Upper(text: string) → string — The text in upper case\n"))
        #expect(prompt.contains("## Action — Button Behavior\n\nPass one step, or Action([...]) with several steps, as a button's action.\n\nAvailable steps:\n- @CopyToClipboard(text: string) — Copies text to the clipboard"))
        #expect(!prompt.contains("@Count("))
    }

    @Test func restrictedSlotsAreExplainedInThePrompt() {
        let prompt = SpecLibrary.library.systemPrompt()

        #expect(prompt.contains("Props typed like `@OpenUrl | @ToAssistant` accept only the steps listed."))
        #expect(prompt.contains("available steps (@ToAssistant, @OpenUrl, @CopyToClipboard)"))
    }
}
