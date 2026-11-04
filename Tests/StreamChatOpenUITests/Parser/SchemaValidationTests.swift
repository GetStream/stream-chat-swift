//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatOpenUI
import Testing

/// Port of `lang-core/src/parser/__tests__/materialize.validation.test.ts`.
@Suite("Schema validation")
struct SchemaValidationTests {
    static let schemaJSON = #"""
    {
      "$defs": {
        "ObjBox": { "properties": { "info": { "type": "object", "properties": { "author": { "type": "string" }, "views": { "type": "number" } }, "required": ["author"] } }, "required": [] },
        "ArrBox": { "properties": { "rows": { "type": "array", "items": { "type": "object", "properties": { "label": { "type": "string" }, "value": { "type": "number" } }, "required": ["label"] } } }, "required": [] },
        "TagBox": { "properties": { "tags": { "type": "array", "items": { "type": "string" } } }, "required": [] },
        "EnumBox": { "properties": { "status": { "enum": ["active", "inactive"] } }, "required": [] },
        "AnyBox": { "properties": { "combo": { "anyOf": [{ "type": "string" }, { "type": "number" }] } }, "required": [] },
        "ScalarBox": { "properties": { "title": { "type": "string" }, "count": { "type": "number" }, "flag": { "type": "boolean" } }, "required": [] },
        "ListBox": { "properties": { "children": { "type": "array" } }, "required": [] },
        "CardBox": { "properties": { "text": { "type": "string" } }, "required": [] },
        "ReqScalar": { "properties": { "title": { "type": "string" } }, "required": ["title"] },
        "DefBox": { "properties": { "theme": { "type": "string", "default": "dark" } }, "required": ["theme"] },
        "SlotBox": { "properties": { "children": { "type": "array", "items": { "anyOf": [{ "$ref": "#/$defs/CardBox" }] } } }, "required": [] },
        "ChartBox": { "properties": { "labels": { "type": "array", "items": { "type": "string" } }, "variant": { "enum": ["grouped", "stacked"] } }, "required": ["labels"] },
        "NestDefBox": { "properties": { "cfg": { "type": "object", "properties": { "mode": { "enum": ["fast", "slow"], "default": "fast" }, "retries": { "type": "number", "default": 3 } }, "required": ["mode"] } }, "required": [] }
      }
    }
    """#

    let parser: OpenUIParser

    init() throws {
        parser = OpenUIParser(schema: try OpenUIJSON.parse(Self.schemaJSON))
    }

    func errors(_ source: String) -> [ValidationError] {
        parser.parse(source).meta.errors
    }

    func directErrors(_ value: OpenUIValue, _ schema: OpenUIValue, partial: Bool = false) -> [ValidationError] {
        let context = MaterializeContext(symbols: [:], catalog: nil, partial: partial, currentStatementId: nil, unreached: nil)
        var copy = value
        SchemaValidation.validate(&copy, schema: schema, component: "X", path: "/p", context: context)
        return context.errors
    }

    // MARK: recursive descent & error reporting

    @Test func reportsViolationsWithJSONPointerPaths() {
        #expect(errors(#"root = ObjBox({ author: "ann", views: 3 })"#).isEmpty)

        let leaf = errors(#"root = ObjBox({ author: "ann", views: "lots" })"#).first
        #expect(leaf?.code == .typeMismatch)
        #expect(leaf?.component == "ObjBox")
        #expect(leaf?.path == "/info/views")

        #expect(errors(#"root = ArrBox([{ label: "a", value: "x" }])"#).first?.path == "/rows/0/value")

        let missing = errors("root = ObjBox({ views: 3 })").first
        #expect(missing?.code == .missingRequired)
        #expect(missing?.path == "/info/author")

        let nulled = errors("root = ObjBox({ author: null, views: 3 })").first
        #expect(nulled?.code == .nullRequired)
        #expect(nulled?.path == "/info/author")
    }

    @Test func reportsContainerShapeMismatchesAndAccumulates() {
        #expect(errors(#"root = ObjBox("hello")"#).first?.message.contains("expects object but got string") == true)
        #expect(errors("root = TagBox(42)").first?.message.contains("expects array but got number") == true)
        #expect(errors("root = ScalarBox({ a: $x })").first?.message.contains("expects string but got object") == true)

        let byPath = errors(#"root = ArrBox([{ label: 1 }, { value: "x" }])"#)
            .map { "\($0.code.rawValue):\($0.path)" }
            .sorted()
        #expect(byPath == [
            "missing-required:/rows/1/label",
            "type-mismatch:/rows/0/label",
            "type-mismatch:/rows/1/value"
        ])

        #expect(errors(#"root = ScalarBox(1, 1, true, "extra")"#).map(\.code.rawValue).sorted() == ["excess-args", "type-mismatch"])
    }

    @Test func messagesAreSelfSufficientAndAttributed() {
        #expect(errors("root = ReqScalar()").first?.message == #"missing required field "/title" — signature: ReqScalar(title*: string)"#)
        #expect(errors(#"root = ChartBox(null, "grouped")"#).first?.message
            == #"required field "/labels" cannot be null — signature: ChartBox(labels*: array, variant: "grouped"|"stacked")"#)
        #expect(errors("root = Nope()").first?.message.contains("Available components: ObjBox, ArrBox") == true)

        let attributed = errors("root = ListBox([inner])\ninner = ObjBox({ author: \"ann\", views: \"lots\" })").first
        #expect(attributed?.component == "ObjBox")
        #expect(attributed?.statementId == "inner")
    }

    // MARK: the edge rule

    @Test func prunesInvalidValuesOnOptionalEdgesAndArrayItems() {
        #expect(parser.parse(#"root = ObjBox({ author: "ann", views: "lots" })"#).root?.props["info"] == ["author": "ann"])

        let top = parser.parse("root = ScalarBox(5)")
        #expect(top.root != nil)
        #expect(top.root?.props.contains("title") == false)

        #expect(parser.parse("root = ObjBox({ views: 3 })").root?.props.contains("info") == false)
        #expect(parser.parse(#"root = TagBox(["a", 2, "c"])"#).root?.props["tags"] == ["a", "c"])
        #expect(parser.parse(#"root = ArrBox([{ label: "a", value: 1 }, { value: 2 }])"#).root?.props["rows"] == [["label": "a", "value": 1]])
    }

    @Test func propagatesThroughRequiredEdges() {
        let nested = parser.parse(#"root = ObjBox({ author: { first: "a" }, views: 3 })"#)
        #expect(nested.root != nil)
        #expect(nested.root?.props.contains("info") == false)
        #expect(parser.parse("root = ReqScalar(5)").root == nil)
    }

    @Test func substitutesSchemaDefaults() {
        let def = parser.parse("root = DefBox(5)")
        #expect(def.root?.props["theme"] == "dark")
        #expect(def.meta.errors.count == 1)
        #expect(parser.parse("root = DefBox()").meta.errors.isEmpty)

        let optional = parser.parse(#"root = NestDefBox({ mode: "warp", retries: 1 })"#)
        #expect(optional.root?.props["cfg"] == ["mode": "fast", "retries": 1])
        #expect(optional.meta.errors.first?.code == .typeMismatch)
        #expect(optional.meta.errors.first?.path == "/cfg/mode")

        #expect(parser.parse(#"root = NestDefBox({ mode: "slow", retries: "many" })"#).root?.props["cfg"] == ["mode": "slow", "retries": 3])

        let absent = parser.parse("root = NestDefBox({ retries: 2 })")
        #expect(absent.root?.props["cfg"] == ["mode": "fast", "retries": 2])
        #expect(absent.meta.errors.isEmpty)

        let nulled = parser.parse("root = NestDefBox({ mode: null, retries: 2 })")
        #expect(nulled.root?.props["cfg"] == ["mode": "fast", "retries": 2])
        #expect(nulled.meta.errors.isEmpty)
    }

    // MARK: components in data slots

    @Test func elementsInDataSlotsFollowTheEdgeRule() {
        let dropped = parser.parse(#"root = ChartBox(CardBox("x"), "grouped")"#)
        #expect(dropped.root == nil)
        #expect(dropped.meta.errors.first?.message.contains(#"expects array but got component "CardBox""#) == true)

        let pruned = parser.parse(#"root = ChartBox(["a"], CardBox("x"))"#)
        #expect(pruned.root?.props.contains("variant") == false)
        #expect(pruned.meta.errors.first?.message.contains("expects a literal value but got component") == true)

        #expect(parser.parse(#"root = TagBox(["a", CardBox("x"), "b"])"#).root?.props["tags"] == ["a", "b"])
    }

    @Test func componentSlotsAcceptComponents() {
        let slot = parser.parse(#"root = SlotBox([CardBox("hi"), EnumBox("active")])"#)
        #expect(slot.meta.errors.isEmpty)
        #expect(slot.root?.props["children"]?.arrayValue?.count == 2)

        let errs = errors("root = ObjBox({ author: CardBox(9) })")
        #expect(errs.count == 2)
        #expect(errs.first { $0.component == "CardBox" }?.path == "/text")
        #expect(errs.first { $0.component == "ObjBox" }?.path == "/info/author")
    }

    @Test func dataInComponentSlotIsPruned() {
        let inline = parser.parse(#"root = SlotBox([CardBox("hi"), { text: "a" }, "b", 3, [CardBox("x")]])"#)
        #expect(inline.root?.props["children"]?.arrayValue?.count == 1)
        #expect(inline.meta.errors.map(\.message) == [
            #"field "/children/1" expects CardBox but got plain object"#,
            #"field "/children/2" expects CardBox but got string"#,
            #"field "/children/3" expects CardBox but got number"#,
            #"field "/children/4" expects CardBox but got array"#
        ])

        let viaRef = parser.parse("root = SlotBox(items)\nitems = [{ text: \"a\" }]")
        #expect(viaRef.root?.props["children"] == [])
        #expect(viaRef.meta.errors.first?.code == .typeMismatch)
        #expect(viaRef.meta.errors.first?.path == "/children/0")
    }

    @Test func refToNonComponentDefIsNotAComponentSlot() throws {
        let treeParser = OpenUIParser(schema: try OpenUIJSON.parse(#"""
        {
          "properties": { "Tree": {} },
          "$defs": {
            "Tree": { "properties": { "node": { "$ref": "#/$defs/__schema0" } }, "required": ["node"] },
            "__schema0": { "type": "object", "properties": { "label": { "type": "string" } } }
          }
        }
        """#))
        let result = treeParser.parse(#"root = Tree({ label: "a" })"#)
        #expect(result.meta.errors.isEmpty)
        #expect(result.root?.props["node"] == ["label": "a"])
    }

    // MARK: conservative skips

    @Test func skipsDynamicValuesCompositesAndExtras() {
        #expect(errors(#"root = TagBox(["a", $x])"#).isEmpty)
        #expect(errors(#"root = ObjBox({ author: "a", views: Sum([1, 2]) })"#).isEmpty)
        #expect(errors("root = AnyBox({ anything: true })").isEmpty)
        #expect(errors("root = ObjBox(null)").isEmpty)
        #expect(errors("root = ObjBox()").isEmpty)
        #expect(errors(#"root = ObjBox({ author: "a", bonus: 99 })"#).isEmpty)
        #expect(errors(#"root = ListBox([1, "a", true])"#).isEmpty)
    }

    @Test func skipsUncheckableSchemasAndAppliesLeafEdges() {
        #expect(directErrors(5, .null).isEmpty)
        #expect(directErrors(5, "string").isEmpty)
        #expect(directErrors(5, ["$ref": "#/$defs/Thing"]).isEmpty)
        #expect(directErrors(5, ["oneOf": [["type": "string"]]]).isEmpty)
        #expect(directErrors([5], ["type": "array", "items": [["type": "string"]]]).isEmpty)
        #expect(directErrors("x", ["type": "date"]).isEmpty)
        #expect(directErrors([:], ["type": "object", "required": "author"]).isEmpty)
        #expect(directErrors([:], ["type": "object", "required": ["a"]]).first?.code == .missingRequired)
        #expect(directErrors(1.5, ["type": "integer"]).isEmpty)
        #expect(directErrors("3", ["type": "integer"]).count == 1)
        #expect(directErrors("loose", ["const": "fixed"]).first?.message.contains(#"one of ["fixed"]"#) == true)
        #expect(directErrors(["a": 1], ["enum": ["active"]]).isEmpty)
    }

    // MARK: streaming gates

    @Test func defersRequiredAndEnumChecksWhileStreaming() {
        var required = OpenUIStreamParser(paramMap: parser.paramMap)
        #expect(required.push("root = ObjBox({ views: 3 ").meta.errors.isEmpty)
        let completed = required.push("})\n").meta.errors.first
        #expect(completed?.code == .missingRequired)
        #expect(completed?.path == "/info/author")
        #expect(completed?.statementId == "root")

        var enumParser = OpenUIStreamParser(paramMap: parser.paramMap)
        #expect(enumParser.push(#"root = EnumBox("bogus" "#).meta.errors.isEmpty)
        #expect(enumParser.push(")\n").meta.errors.first?.path == "/status")
    }

    @Test func keepsScalarChecksOnMidStream() {
        var streaming = OpenUIStreamParser(paramMap: parser.paramMap)
        let result = streaming.push(#"root = ObjBox({ author: "a", views: "lots" "#)
        #expect(result.meta.incomplete)
        #expect(result.meta.errors.first { $0.code == .typeMismatch }?.path == "/info/views")
        #expect(directErrors([:], ["type": "object", "required": ["a"]], partial: true).isEmpty)
        #expect(directErrors("act", ["enum": ["active"]], partial: true).isEmpty)
        #expect(directErrors(5, ["type": "string"], partial: true).count == 1)
    }
}
