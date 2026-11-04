//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

/// Tools that return scripted results, set per tool as the interactions go, and record calls.
final class ScriptedTools: OpenUIToolProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var results: [String: OpenUIValue] = [:]
    private var calls: [OpenUIValue] = []

    func setResult(_ result: OpenUIValue, for tool: String) {
        lock.withLock { results[tool] = result }
    }

    var recordedCalls: [OpenUIValue] {
        lock.withLock { calls }
    }

    func callTool(_ name: String, arguments: OpenUIObject) async throws -> OpenUIValue {
        try lock.withLock {
            guard let result = results[name] else {
                throw ToolNotFoundError(toolName: name, availableTools: results.keys.sorted())
            }
            calls.append(["tool": .string(name), "args": OpenUIValue.object(arguments).plainJSON])
            return result
        }
    }
}

/// The interaction cases of the OpenUI 1.0 conformance suite (`spec/fixtures/1.0`, level 2), run
/// the way upstream's `conformance.interactions.test.tsx` runs them: Buttons and Inputs are found by
/// statement name in their Form's scope, a click triggers the Button's action, and typing writes
/// the Input's field.
@MainActor
@Suite("Spec conformance: interactions")
struct SpecInteractionTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let program: String
        let interactions: [OpenUIValue]
        let expected: OpenUIValue
        var testDescription: String { name }
    }

    nonisolated static let cases: [Case] = {
        guard case .array(let items)? = try? Fixtures.json("spec-interactions.json") else { return [] }
        return items.compactMap { item in
            guard let name = item["name"]?.stringValue, let program = item["program"]?.stringValue else { return nil }
            return Case(name: name, program: program, interactions: item["interactions"]?.arrayValue ?? [], expected: item["expected"] ?? [:])
        }
    }()

    /// The spec's test library: its schema as is, `Input.value` and `Select.value` bindable, and
    /// its custom action.
    static let library: ComponentLibrary = {
        let spec = (try? Fixtures.json("spec-library.json")) ?? .null
        return ComponentLibrary(
            specSchema: spec["schema"] ?? [:],
            root: spec["root"]?.stringValue,
            reactiveProps: ["Input": ["value"], "Select": ["value"]],
            customActions: [OpenUICustomAction("CopyToClipboard", description: "Copies text to the clipboard", params: [.required("text", .string)])]
        )
    }()

    struct Control {
        let element: ElementNode
        let formName: String?
    }

    func controls(_ runtime: OpenUIRuntime) -> [String: Control] {
        var controls: [String: Control] = [:]
        func visit(_ value: OpenUIValue?, formName: String?) {
            switch value {
            case .element(let element)?:
                let scope = element.typeName == "Form" ? element.props["name"]?.stringValue : formName
                if let id = element.statementId, controls[id] == nil {
                    controls[id] = Control(element: element, formName: formName)
                }
                element.props.values.forEach { visit($0, formName: scope) }
            case .array(let items)?:
                items.forEach { visit($0, formName: formName) }
            default:
                break
            }
        }
        runtime.root.map { visit(.element($0), formName: nil) }
        return controls
    }

    func settle(_ runtime: OpenUIRuntime) async {
        for _ in 0..<5 {
            _ = await waitUntil { !runtime.isQueryLoading }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    func json(_ event: ActionEvent) -> OpenUIObject {
        [
            "type": .string(event.type),
            "params": OpenUIValue.object(event.params).plainJSON,
            "humanFriendlyMessage": .string(event.humanFriendlyMessage),
            "formState": event.formState.map { OpenUIValue.object($0).plainJSON } ?? .null,
            "formName": event.formName.map(OpenUIValue.string) ?? .null
        ]
    }

    @Test func casesAreLoaded() {
        #expect(Self.cases.count == 12)
    }

    @Test(arguments: cases)
    func interactionsMatchTheSpec(_ testCase: Case) async {
        let tools = ScriptedTools()
        var steps = testCase.interactions[...]
        while let step = steps.first, let tool = step["tool"]?.stringValue {
            tools.setResult(step["result"] ?? .null, for: tool)
            steps = steps.dropFirst()
        }
        var events: [ActionEvent] = []
        let runtime = OpenUIRuntime(library: Self.library, toolProvider: tools)
        runtime.onAction = { events.append($0) }
        runtime.update(response: testCase.program, isStreaming: false)
        await settle(runtime)

        for step in steps {
            if let tool = step["tool"]?.stringValue {
                tools.setResult(step["result"] ?? .null, for: tool)
                continue
            }
            if let id = step["click"]?.stringValue {
                let control = try? #require(controls(runtime)[id], "\(testCase.name): nothing rendered for \(id)")
                guard let control else { return }
                await runtime.triggerAction(
                    label: control.element.props["label"]?.stringValue ?? "",
                    formName: control.formName,
                    action: control.element.props["action"]
                )
            } else if let typing = step["type"]?.arrayValue, let id = typing.first?.stringValue {
                let control = try? #require(controls(runtime)[id], "\(testCase.name): nothing rendered for \(id)")
                guard let control else { return }
                runtime.stateField(
                    name: control.element.props["name"]?.stringValue ?? "",
                    binding: control.element.props["value"],
                    formName: control.formName,
                    componentType: "input"
                ).set(typing.count > 1 ? typing[1] : "")
            }
            await settle(runtime)
        }

        let expectedEvents = testCase.expected["events"]?.arrayValue ?? []
        #expect(events.count == expectedEvents.count, "\(testCase.name): events \(events.map { OpenUIValue.object(json($0)) })")
        for (expected, actual) in zip(expectedEvents, events.map(json)) {
            for (key, value) in expected.objectValue?.entries ?? [] {
                let difference = firstDifference(actual[key] ?? .null, value.plainJSON)
                #expect(difference == nil, "\(testCase.name): event \(key): \(difference ?? "")")
            }
        }
        for (key, value) in testCase.expected["state"]?.objectValue?.entries ?? [] {
            let actual = runtime.store.get(key).map(\.plainJSON) ?? .null
            #expect(firstDifference(actual, value) == nil, "\(testCase.name): state \(key) is \(actual)")
        }
        if let expectedCalls = testCase.expected["toolCalls"] {
            let calls = tools.recordedCalls.enumerated().filter { index, call in index == 0 || call != tools.recordedCalls[index - 1] }.map(\.element)
            #expect(firstDifference(.array(calls), expectedCalls) == nil, "\(testCase.name): tool calls \(calls)")
        }
    }
}
