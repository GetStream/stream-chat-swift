//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

/// Verifies the Swift component libraries are wire-compatible with the upstream React libraries:
/// identical component signatures, descriptions, groups and JSON Schema.
@Suite("Library conformance with the upstream specs")
struct LibraryConformanceTests {
    static let pairs: [(String, ComponentLibrary, String)] = [
        ("chat", .openUIChat, "upstream-chat-library.spec.json"),
        ("standard", .openUI, "upstream-playground-library.spec.json")
    ]

    @Test(arguments: [0, 1])
    func componentsMatch(_ index: Int) throws {
        let (name, library, file) = Self.pairs[index]
        let upstream = try Fixtures.json(file)
        let actual = library.specJSON

        #expect(actual["root"] == upstream["root"], "\(name) root")
        let upstreamComponents = try #require(upstream["components"]?.objectValue)
        let actualComponents = try #require(actual["components"]?.objectValue)
        #expect(actualComponents.keys == upstreamComponents.keys, "\(name) component order")
        for key in upstreamComponents.keys {
            #expect(actualComponents[key]?["signature"] == upstreamComponents[key]?["signature"], "\(name).\(key) signature")
            #expect(actualComponents[key]?["description"] == upstreamComponents[key]?["description"], "\(name).\(key) description")
        }
        #expect(firstDifference(actual["componentGroups"]!, upstream["componentGroups"]!) == nil, "\(name) groups")
    }

    @Test(arguments: [0, 1])
    func defaultPromptOptionsMatchUpstreamPromptOptions(_ index: Int) throws {
        let (name, library, file) = Self.pairs[index]
        let upstream = try #require(try Fixtures.json(file)["promptOptions"])

        let examples = upstream["examples"]?.arrayValue?.compactMap(\.stringValue) ?? []
        let rules = upstream["additionalRules"]?.arrayValue?.compactMap(\.stringValue) ?? []

        #expect(library.defaultPromptOptions.examples == examples, "\(name) examples")
        if !rules.isEmpty {
            #expect(library.defaultPromptOptions.additionalRules == rules, "\(name) rules")
        }
    }

    @Test(arguments: [0, 1])
    func jsonSchemaMatches(_ index: Int) throws {
        let (name, library, file) = Self.pairs[index]
        let upstream = try #require(try Fixtures.json(file)["schema"])
        let actual = library.jsonSchema

        let upstreamDefs = try #require(upstream["$defs"]?.objectValue)
        let actualDefs = try #require(actual["$defs"]?.objectValue)
        // $defs order drives the "Available components" listing in error messages.
        #expect(actualDefs.keys == upstreamDefs.keys, "\(name) $defs order")
        for key in upstreamDefs.keys {
            let difference = firstDifference(actualDefs[key] ?? .null, upstreamDefs[key]!)
            #expect(difference == nil, "\(name).\(key): \(difference ?? "")")
            // Positional order = properties order.
            #expect(actualDefs[key]?["properties"]?.objectValue?.keys == upstreamDefs[key]?["properties"]?.objectValue?.keys, "\(name).\(key) property order")
        }
        for key in ["$schema", "type", "properties", "required", "additionalProperties"] {
            #expect(actual[key] == upstream[key], "\(name) \(key)")
        }
    }

    @Test func reactivePropsMatchUpstreamBindings() throws {
        let upstream = try Fixtures.json("upstream-chat-library.spec.json")
        let resolver = SignatureReactiveResolver(spec: upstream)
        for component in ComponentLibrary.openUIChat.components {
            for prop in component.schema.props {
                #expect(
                    ComponentLibrary.openUIChat.isReactiveProp(component: component.name, prop: prop.name)
                        == resolver.isReactiveProp(component: component.name, prop: prop.name),
                    "\(component.name).\(prop.name)"
                )
            }
        }
    }
}

/// Golden tests for system prompt generation against upstream `generateSystemPrompt`.
@Suite("Prompt generation conformance")
struct PromptConformanceTests {
    struct Golden: Sendable, CustomTestStringConvertible {
        let name: String
        let library: String
        let options: OpenUIValue
        let prompt: String
        var testDescription: String { name }
    }

    static let goldens: [Golden] = {
        guard case .array(let items)? = try? Fixtures.json("prompt-goldens.json") else { return [] }
        return items.compactMap { item in
            guard let name = item["name"]?.stringValue,
                  let library = item["library"]?.stringValue,
                  let prompt = item["prompt"]?.stringValue else { return nil }
            return Golden(name: name, library: library, options: item["options"] ?? [:], prompt: prompt)
        }
    }()

    static func promptOptions(_ json: OpenUIValue) -> PromptOptions {
        let strings: (String) -> [String] = { key in json[key]?.arrayValue?.compactMap(\.stringValue) ?? [] }
        let tools: [ToolDescriptor] = (json["tools"]?.arrayValue ?? []).map { tool in
            if let name = tool.stringValue { return .name(name) }
            return .spec(ToolSpec(
                name: tool["name"]?.stringValue ?? "",
                description: tool["description"]?.stringValue,
                inputSchema: tool["inputSchema"] ?? [:],
                outputSchema: tool["outputSchema"] ?? [:]
            ))
        }
        return PromptOptions(
            preamble: json["preamble"]?.stringValue,
            additionalRules: strings("additionalRules"),
            examples: strings("examples"),
            toolExamples: strings("toolExamples"),
            tools: tools,
            editMode: json["editMode"]?.boolValue ?? false,
            inlineMode: json["inlineMode"]?.boolValue ?? false,
            toolCalls: json["toolCalls"]?.boolValue,
            bindings: json["bindings"]?.boolValue,
            builtinFunctions: json["builtinFunctions"]?.boolValue
        )
    }

    static func specFile(_ library: String) -> String {
        switch library {
        case "chat": return "upstream-chat-library.spec.json"
        case "spec": return "spec-library.json"
        default: return "upstream-playground-library.spec.json"
        }
    }

    static func swiftLibrary(_ library: String) -> ComponentLibrary {
        switch library {
        case "chat": return .openUIChat
        case "spec": return SpecLibrary.library
        default: return .openUI
        }
    }

    static func calls(_ json: OpenUIValue?) -> [PromptSpec.Component] {
        (json?.objectValue?.entries ?? []).map { name, call in
            PromptSpec.Component(name: name, signature: call["signature"]?.stringValue ?? "", description: call["description"]?.stringValue)
        }
    }

    static func firstLineDifference(_ actual: String, _ expected: String) -> String? {
        if actual == expected { return nil }
        let a = actual.components(separatedBy: "\n")
        let e = expected.components(separatedBy: "\n")
        for index in 0..<max(a.count, e.count) {
            let left = index < a.count ? a[index] : "<missing>"
            let right = index < e.count ? e[index] : "<missing>"
            if left != right {
                return "line \(index + 1):\n  actual:   \(left)\n  expected: \(right)"
            }
        }
        return "lengths differ"
    }

    @Test func goldensAreLoaded() {
        #expect(Self.goldens.count == 14)
        #expect(Set(Self.goldens.map(\.library)) == ["chat", "standard", "spec"])
    }

    /// The generator alone, fed the upstream spec.
    @Test(arguments: goldens)
    func generatorMatchesUpstream(_ golden: Golden) throws {
        let spec = try Fixtures.json(Self.specFile(golden.library))
        let components = (spec["components"]?.objectValue?.entries ?? []).map { name, component in
            PromptSpec.Component(name: name, signature: component["signature"]?.stringValue ?? "", description: component["description"]?.stringValue)
        }
        let groups = (spec["componentGroups"]?.arrayValue ?? []).map { group in
            ComponentGroup(
                name: group["name"]?.stringValue ?? "",
                components: group["components"]?.arrayValue?.compactMap(\.stringValue) ?? [],
                notes: group["notes"]?.arrayValue?.compactMap(\.stringValue) ?? []
            )
        }
        let prompt = PromptGenerator.generate(PromptSpec(
            root: spec["root"]?.stringValue,
            components: components,
            componentGroups: groups,
            functions: Self.calls(spec["functions"]),
            actions: Self.calls(spec["actions"]),
            options: Self.promptOptions(golden.options)
        ))
        let difference = Self.firstLineDifference(prompt, golden.prompt)
        #expect(difference == nil, "\(golden.name): \(difference ?? "")")
    }

    /// End to end: the Swift library definitions + generator.
    @Test(arguments: goldens)
    func swiftLibraryPromptMatchesUpstream(_ golden: Golden) {
        let prompt = Self.swiftLibrary(golden.library).systemPrompt(Self.promptOptions(golden.options))
        let difference = Self.firstLineDifference(prompt, golden.prompt)
        #expect(difference == nil, "\(golden.name): \(difference ?? "")")
    }

    @Test func defaultPromptOptionsMatchUpstream() {
        let chat = Self.goldens.first { $0.name == "chat-default" }
        let standard = Self.goldens.first { $0.name == "standard-default" }
        #expect(ComponentLibrary.openUIChat.systemPrompt() == chat?.prompt)
        #expect(ComponentLibrary.openUI.systemPrompt() == standard?.prompt)
    }
}
