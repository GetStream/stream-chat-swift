//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import Testing

/// Reactive props derived from upstream signatures (`value?: $binding<string>`).
struct SignatureReactiveResolver: ReactivePropResolver {
    let reactive: Set<String>

    init(spec: OpenUIValue) {
        var reactive = Set<String>()
        for (name, component) in spec["components"]?.objectValue?.entries ?? [] {
            let signature = component["signature"]?.stringValue ?? ""
            let regex = try! NSRegularExpression(pattern: #"(\w+)\??: \$binding<"#)
            let range = NSRange(signature.startIndex..., in: signature)
            for match in regex.matches(in: signature, range: range) {
                if let propRange = Range(match.range(at: 1), in: signature) {
                    reactive.insert("\(name).\(signature[propRange])")
                }
            }
        }
        self.reactive = reactive
    }

    func isReactiveProp(component: String, prop: String) -> Bool {
        reactive.contains("\(component).\(prop)")
    }
}

/// Differential tests of the evaluator against `evaluateElementProps` / `evaluate` in the reference.
@Suite("Evaluator conformance with the reference implementation")
struct EvaluatorConformanceTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let library: String
        let input: String
        let state: OpenUIObject
        let refs: OpenUIObject
        let evaluatedRoot: OpenUIValue
        let queries: OpenUIValue
        let runtimeErrors: OpenUIValue
        var testDescription: String { name }
    }

    static let cases: [Case] = {
        guard case .array(let items)? = try? Fixtures.json("evaluator-conformance.json") else { return [] }
        return items.compactMap { item in
            guard let name = item["name"]?.stringValue,
                  let library = item["library"]?.stringValue,
                  let input = item["input"]?.stringValue else { return nil }
            return Case(
                name: name,
                library: library,
                input: input,
                state: item["state"]?.objectValue ?? [:],
                refs: item["refs"]?.objectValue ?? [:],
                evaluatedRoot: item["evaluatedRoot"] ?? .null,
                queries: item["queries"] ?? .array([]),
                runtimeErrors: item["runtimeErrors"] ?? .array([])
            )
        }
    }()

    static let libraries: [String: (ParamMap, String?, SignatureReactiveResolver)] = {
        var result: [String: (ParamMap, String?, SignatureReactiveResolver)] = [:]
        for (name, file) in [("chat", "upstream-chat-library.spec.json"), ("playground", "upstream-playground-library.spec.json")] {
            if let spec = try? Fixtures.json(file), let schema = spec["schema"] {
                result[name] = (OpenUIParser.compileSchema(schema), spec["root"]?.stringValue, SignatureReactiveResolver(spec: spec))
            }
        }
        if let spec = try? Fixtures.json("spec-library.json"), let schema = spec["schema"] {
            result["spec"] = (OpenUIParser.compileSchema(schema), spec["root"]?.stringValue, SignatureReactiveResolver(spec: spec))
        }
        return result
    }()

    // The spec library's function and action, as upstream's conformance runner supplies them.
    static let specFunctions: [String: OpenUIFunction] = [
        "Upper": OpenUIFunction("Upper", description: "The text in upper case", params: [.required("text", .string)], returns: .string) { args in
            .string((args["text"].map { JS.isNullish($0) ? "" : JS.toString($0) } ?? "").uppercased())
        }
    ]
    static let specActions: [String: OpenUICustomAction] = [
        "CopyToClipboard": OpenUICustomAction("CopyToClipboard", description: "Copies text to the clipboard", params: [.required("text", .string)])
    ]

    @Test func fixturesAreLoaded() {
        #expect(Self.cases.count > 180)
        #expect(Self.libraries.count == 3)
    }

    @Test(arguments: cases)
    func evaluationMatchesReference(_ testCase: Case) throws {
        let (paramMap, rootName, resolver) = try #require(Self.libraries[testCase.library])
        let result = OpenUIParser(paramMap: paramMap, rootName: rootName).parse(testCase.input)

        var store = result.stateDeclarations
        for (key, value) in testCase.state.entries { store[key] = value }
        let refs = testCase.refs
        let context = EvaluationContext(
            getState: { name in
                let value = store[name]
                if case .object(let object)? = value, let wrapped = object["value"] { return wrapped }
                return value
            },
            resolveRef: { refs[$0] },
            functions: testCase.library == "spec" ? Self.specFunctions : [:],
            actions: testCase.library == "spec" ? Self.specActions : [:]
        )

        let (evaluatedRoot, runtimeErrors) = PropEvaluator.evaluateRoot(result, context, resolver)
        let actualRoot = evaluatedRoot.map { OpenUIValue.element($0).plainJSON } ?? .null
        if testCase.name == "expressions" {
            // Guard against vacuous passes: the expression case must render real values.
            #expect(actualRoot["props"]?["children"]?.arrayValue?.count ?? 0 >= 100)
            #expect(actualRoot["props"]?["children"]?["0"]?["props"]?["text"] == "0.10.2")
        }
        let rootDifference = firstDifference(actualRoot, testCase.evaluatedRoot)
        #expect(rootDifference == nil, "\(testCase.name): \(rootDifference ?? "")")

        let queries: [OpenUIValue] = result.queryStatements.map { query in
            func eval(_ node: ASTNode?) -> OpenUIValue {
                guard let node else { return .null }
                return Evaluator.evaluate(node, context)?.plainJSON ?? .null
            }
            return [
                "statementId": .string(query.statementId),
                "toolName": query.toolAST.map { Evaluator.evaluate($0, context)?.plainJSON ?? .null } ?? "",
                "args": eval(query.argsAST),
                "defaults": eval(query.defaultsAST),
                "refresh": eval(query.refreshAST)
            ]
        }
        let queryDifference = firstDifference(.array(queries), testCase.queries)
        #expect(queryDifference == nil, "\(testCase.name) queries: \(queryDifference ?? "")")

        let errors: [OpenUIValue] = runtimeErrors.map { error in
            var object: OpenUIObject = ["source": .string(error.source.rawValue), "code": .string(error.code)]
            if let component = error.component { object["component"] = .string(component) }
            if let statementId = error.statementId { object["statementId"] = .string(statementId) }
            object["message"] = .string(error.message)
            if let hint = error.hint { object["hint"] = .string(hint) }
            return .object(object)
        }
        let errorDifference = firstDifference(.array(errors), testCase.runtimeErrors)
        #expect(errorDifference == nil, "\(testCase.name) runtime errors: \(errorDifference ?? "")")
    }
}
