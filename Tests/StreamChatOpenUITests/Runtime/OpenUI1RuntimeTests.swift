//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

struct FunctionFailure: Error, LocalizedError {
    var errorDescription: String? { "division by zero" }
}

@MainActor
@Suite("OpenUI 1.0 runtime")
struct OpenUI1RuntimeTests {
    static let percent = OpenUIFunction(
        "Percent",
        description: "Share of a total, in percent",
        params: [.required("part", .number), .required("total", .number)],
        returns: .number
    ) { args in
        let total = args["total"]?.numberValue ?? 0
        if total == 0 { throw FunctionFailure() }
        return .number((args["part"]?.numberValue ?? 0) / total * 100)
    }

    static let copy = OpenUICustomAction("CopyToClipboard", description: "Copies text", params: [.required("text", .string)])

    static let library = ComponentLibrary.openUIChat.adding([]).withCalls(functions: [percent], actions: [copy])

    func makeRuntime(_ program: String, library: ComponentLibrary = Self.library, events: Box<[ActionEvent]>? = nil) -> OpenUIRuntime {
        let runtime = OpenUIRuntime(library: library)
        if let events {
            runtime.onAction = { events.value.append($0) }
        }
        runtime.update(response: program, isStreaming: false)
        return runtime
    }

    func element(_ runtime: OpenUIRuntime, _ statementId: String) -> ElementNode? {
        var found: ElementNode?
        func visit(_ value: OpenUIValue?) {
            switch value {
            case .element(let element)?:
                if element.statementId == statementId { found = element }
                for item in element.props.values { visit(item) }
            case .array(let items)?:
                for item in items { visit(item) }
            default:
                break
            }
        }
        runtime.root.map { visit(.element($0)) }
        return found
    }

    func click(_ runtime: OpenUIRuntime, _ statementId: String) async {
        let button = element(runtime, statementId)
        await runtime.triggerAction(label: button?.props["label"]?.stringValue ?? "", action: button?.props["action"])
    }

    @Test func aBareStepRunsWithoutActionWrapper() async {
        let events = Box<[ActionEvent]>([])
        let runtime = makeRuntime("""
        $sel = "a"
        root = Card([ask, pick])
        ask = Button("Ask", @ToAssistant("Tell me more"))
        pick = Button("Pick", @Set($sel, "b"))
        """, events: events)

        await click(runtime, "ask")
        await click(runtime, "pick")

        #expect(events.value.map(\.humanFriendlyMessage) == ["Tell me more"])
        #expect(events.value.map(\.label) == ["Ask"], "the event says which control the person tapped")
        #expect(runtime.store.get("$sel") == "b")
    }

    @Test func nestedPlansFlattenAndAnInvalidStepDoesNothing() async {
        let events = Box<[ActionEvent]>([])
        let runtime = makeRuntime("""
        $a = 0
        root = Card([go, broken])
        prepare = Action([@Set($a, 1)])
        go = Button("Go", Action([prepare, @ToAssistant("Done")]))
        broken = Button("Broken", @Run(missing))
        """, events: events)

        await click(runtime, "go")
        await click(runtime, "broken")

        #expect(runtime.store.get("$a") == 1)
        #expect(events.value.map(\.humanFriendlyMessage) == ["Done"], "an invalid step is an empty plan, not the label")
    }

    @Test func toAssistantContextIsAnyValue() async throws {
        let events = Box<[ActionEvent]>([])
        let runtime = makeRuntime("""
        root = Card([save, zero])
        save = Button("Save", @ToAssistant("Save", {orderId: 42}))
        zero = Button("Zero", @ToAssistant("Zero", 0))
        """, events: events)

        await click(runtime, "save")
        await click(runtime, "zero")

        #expect(events.value.map(\.context) == [["orderId": 42], 0])
        let message = MessageEnvelope.parse(events.value[0].assistantMessage)
        #expect(message.content == "Save")
        #expect(message.context == ["User clicked: Save", .object(events.value[0].formState ?? [:]), ["orderId": 42]])
    }

    @Test func formStateIsReadWhenEachStepRuns() async {
        let events = Box<[ActionEvent]>([])
        let runtime = makeRuntime("""
        $note = "old"
        root = Card([send])
        send = Button("Send", Action([@Set($note, "new"), @ToAssistant("Send")]))
        """, events: events)

        await click(runtime, "send")

        #expect(events.value.first?.formState?["$note"] == "new")
    }

    @Test func customActionsReachTheHostWithTheirArguments() async {
        let events = Box<[ActionEvent]>([])
        let runtime = makeRuntime("""
        $id = "abc"
        root = Card([copy, wrong, legacy])
        copy = Button("Copy", Action([@CopyToClipboard($id), @ToAssistant("Copied")]))
        wrong = Button("Wrong", @CopyToClipboard(5))
        legacy = Button("Legacy", {type: "CopyToClipboard", params: {text: "forged"}})
        """, events: events)

        await click(runtime, "copy")
        await click(runtime, "wrong")
        await click(runtime, "legacy")

        #expect(events.value.map(\.type) == ["CopyToClipboard", BuiltinActionType.continueConversation])
        #expect(events.value.first?.params == ["text": "abc"])
    }

    @Test func dataCannotPoseAsACustomAction() async {
        let events = Box<[ActionEvent]>([])
        let runtime = makeRuntime("""
        $plan = {steps: [{type: "custom_action", name: "CopyToClipboard", params: {text: "forged"}}]}
        root = Card([forged])
        forged = Button("Forged", $plan)
        """, events: events)

        await click(runtime, "forged")

        #expect(events.value.allSatisfy { $0.type != "CopyToClipboard" })
    }

    @Test func libraryFunctionsRunAndReportFailures() throws {
        let runtime = makeRuntime("""
        root = Card([ok, failing])
        ok = TextContent("" + @Percent(1, 4))
        failing = TextContent("" + @Percent(1, 0))
        """)

        #expect(element(runtime, "ok")?.props["text"] == "25")
        #expect(element(runtime, "failing")?.props["text"] == "", "like upstream, + reads null as an empty string")
        let error = try #require(runtime.errors.first { $0.code == "runtime-error" })
        #expect(error.message == "Evaluating prop \"text\" on TextContent failed: @Percent threw: division by zero")
        #expect(error.statementId == "failing")
    }

    @Test func anUnknownFunctionIsNullWithAnError() {
        let runtime = makeRuntime("""
        root = Card([TextContent("x"), title])
        title = TextContent(@Nope(1))
        """)

        #expect(runtime.parseResult?.meta.errors.contains { $0.code == .unknownFunction && $0.component == "Nope" } == true)
        #expect(element(runtime, "title") == nil, "a required prop that is null drops the component")
    }

    @Test func aTernaryRootFollowsState() {
        let runtime = makeRuntime("""
        $dark = false
        root = $dark ? darkPage : lightPage
        darkPage = Card([TextContent("Dark")])
        lightPage = Card([TextContent("Light")])
        """)
        let text = { runtime.root?.props["children"]?.arrayValue?.first?.elementValue?.props["text"] }
        #expect(text() == "Light")

        runtime.store.set("$dark", true)

        #expect(text() == "Dark")
    }

    @Test func programsWithoutAnEntryReportNoRoot() {
        let runtime = makeRuntime("title = TextContent(\"Orders\")")

        #expect(runtime.root == nil)
        #expect(runtime.errors.map(\.code) == ["no-root"])
    }

    @Test func aFallbackEntryRendersWithAWarning() throws {
        let runtime = makeRuntime("main = Card([TextContent(\"Hi\")])")

        #expect(runtime.root?.statementId == "main")
        let warning = try #require(runtime.errors.first)
        #expect(warning.code == "no-root")
        #expect(warning.isWarning)
    }

    @Test func theEndOfTheStreamDeclaresATrailingStateName() {
        let runtime = OpenUIRuntime(library: Self.library)
        let program = "root = Card([TextContent($count)])\n$total = $co"

        runtime.update(response: program, isStreaming: true)
        #expect(runtime.parseResult?.stateDeclarations.contains("$co") == false)

        runtime.update(response: program, isStreaming: false)
        #expect(runtime.parseResult?.stateDeclarations.contains("$co") == true)
    }

    @Test func aResetValueFollowsItsDeclarationAgain() async {
        let runtime = OpenUIRuntime(library: Self.library)
        runtime.update(response: """
        $title = "Draft"
        root = Card([reset])
        reset = Button("Reset", @Reset($title))
        """, isStreaming: true)
        runtime.store.set("$title", "Typed")
        await click(runtime, "reset")
        #expect(runtime.store.get("$title") == "Draft")

        runtime.update(response: """
        $title = "Draft 2"
        root = Card([reset])
        reset = Button("Reset", @Reset($title))
        """, isStreaming: false)

        #expect(runtime.store.get("$title") == "Draft 2")
    }

    @Test func anInnerEachShadowsTheOuterLoopVariable() {
        let runtime = makeRuntime("""
        $groups = [{items: ["a", "b"]}, {items: ["c"]}]
        root = Stack([list])
        list = Stack(@Each($groups, "g", Stack(@Each(g.items, "g", TextContent(g)))))
        """, library: .openUI)

        let texts = OpenUIJSON.stringify(element(runtime, "list").map { OpenUIValue.element($0).plainJSON } ?? .null)

        #expect(texts.contains(#""text":"a""#))
        #expect(texts.contains(#""text":"c""#))
    }

    @Test func stringEqualityComparesCodeUnitsLikeJavaScript() {
        #expect(!JS.looseEquals("é", "e\u{301}"))
        #expect(JS.looseEquals("é", "é"))
        #expect(!JS.sameValueZero("é", "e\u{301}"))
    }

    @Test func declaredDefaultsDoNotFireStateUpdates() {
        let updates = Box<[OpenUIObject]>([])
        let runtime = OpenUIRuntime(library: Self.library)
        runtime.onStateUpdate = { updates.value.append($0) }

        runtime.update(response: "$a = 1\nroot = Card([TextContent(\"\" + $a)])", isStreaming: false)
        #expect(updates.value.isEmpty)

        runtime.store.set("$a", 2)
        #expect(updates.value.count == 1)
    }
}

@MainActor
final class Box<Value> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension ComponentLibrary {
    func withCalls(functions: [OpenUIFunction], actions: [OpenUICustomAction]) -> ComponentLibrary {
        ComponentLibrary(
            root: root,
            components: components,
            componentGroups: componentGroups,
            defaultPromptOptions: defaultPromptOptions,
            functions: functions,
            customActions: actions
        )
    }
}
