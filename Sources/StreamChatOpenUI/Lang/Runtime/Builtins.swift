//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The `@`-prefixed builtin functions and action steps of OpenUI Lang (port of `builtins.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum Builtins {
    /// A data builtin: its prompt signature/description and runtime implementation.
    struct Definition: Sendable {
        /// PascalCase name, e.g. `Count`.
        let name: String
        /// Signature for prompt docs, e.g. `Count(array) → number`.
        let signature: String
        /// One-line description for prompt docs.
        let description: String
        let function: @Sendable ([OpenUIValue?]) -> OpenUIValue
    }

    /// Data builtins in registry order (the order matters for prompt generation).
    static let definitions: [Definition] = [
        Definition(name: "Count", signature: "Count(array) → number", description: "Returns array length") { args in
            guard case .array(let items)? = args.first ?? nil else { return .number(0) }
            return .number(Double(items.count))
        },
        Definition(name: "First", signature: "First(array) → element", description: "Returns first element of array") { args in
            guard case .array(let items)? = args.first ?? nil else { return .null }
            return items.first ?? .null
        },
        Definition(name: "Last", signature: "Last(array) → element", description: "Returns last element of array") { args in
            guard case .array(let items)? = args.first ?? nil else { return .null }
            return items.last ?? .null
        },
        Definition(name: "Sum", signature: "Sum(numbers[]) → number", description: "Sum of numeric array") { args in
            guard case .array(let items)? = args.first ?? nil else { return .number(0) }
            return .number(items.reduce(0) { $0 + JS.toNumber($1) })
        },
        Definition(name: "Avg", signature: "Avg(numbers[]) → number", description: "Average of numeric array") { args in
            guard case .array(let items)? = args.first ?? nil, !items.isEmpty else { return .number(0) }
            return .number(items.reduce(0) { $0 + JS.toNumber($1) } / Double(items.count))
        },
        Definition(name: "Min", signature: "Min(numbers[]) → number", description: "Minimum value in array") { args in
            guard case .array(let items)? = args.first ?? nil, let first = items.first else { return .number(0) }
            return .number(items.reduce(JS.toNumber(first)) { JS.min($0, JS.toNumber($1)) })
        },
        Definition(name: "Max", signature: "Max(numbers[]) → number", description: "Maximum value in array") { args in
            guard case .array(let items)? = args.first ?? nil, let first = items.first else { return .number(0) }
            return .number(items.reduce(JS.toNumber(first)) { JS.max($0, JS.toNumber($1)) })
        },
        Definition(
            name: "Sort",
            signature: "Sort(array, field, direction?) → sorted array",
            description: "Sort array by field. Direction: \"asc\" (default) or \"desc\""
        ) { args in
            sort(args)
        },
        Definition(
            name: "Filter",
            signature: "Filter(array, field, operator: \"==\" | \"!=\" | \">\" | \"<\" | \">=\" | \"<=\" | \"contains\", value) → filtered array",
            description: "Filter array by field value"
        ) { args in
            filter(args)
        },
        Definition(name: "Round", signature: "Round(number, decimals?) → number", description: "Round to N decimal places (default 0)") { args in
            let number = JS.toNumber(argument(args, 0))
            let decimalsArgument = argument(args, 1)
            let decimals = JS.isNullish(decimalsArgument) ? 0 : JS.toNumber(decimalsArgument)
            let factor = pow(10, decimals)
            return .number(JS.round(number * factor) / factor)
        },
        Definition(name: "Abs", signature: "Abs(number) → number", description: "Absolute value") { args in
            .number(abs(JS.toNumber(argument(args, 0))))
        },
        Definition(name: "Floor", signature: "Floor(number) → number", description: "Round down to nearest integer") { args in
            .number(JS.toNumber(argument(args, 0)).rounded(.down))
        },
        Definition(name: "Ceil", signature: "Ceil(number) → number", description: "Round up to nearest integer") { args in
            .number(JS.toNumber(argument(args, 0)).rounded(.up))
        }
    ]

    static let definitionsByName: [String: Definition] = Dictionary(
        uniqueKeysWithValues: definitions.map { ($0.name, $0) }
    )

    /// Lazy builtins receive AST nodes and control their own evaluation.
    static let lazyNames: Set<String> = ["Each"]

    /// Prompt docs for lazy builtins.
    static let lazyDefinitions: [(signature: String, description: String)] = [
        (
            "Each(array, varName, template)",
            "Evaluate template for each element. varName is the loop variable — use it ONLY inside the template expression (inline). Do NOT create a separate statement for the template."
        )
    ]

    /// Parser-level action step names → runtime step type values.
    static let actionSteps: [String: String] = [
        "Run": ActionStepType.run,
        "ToAssistant": ActionStepType.continueConversation,
        "OpenUrl": ActionStepType.openURL,
        "Set": ActionStepType.set,
        "Reset": ActionStepType.reset
    ]

    /// All action expression names (the steps plus the `Action` container).
    static let actionNames: Set<String> = Set(["Action"]).union(actionSteps.keys)

    static let allNames: Set<String> = Set(definitions.map(\.name)).union(lazyNames).union(actionNames)

    /// Whether `name` is a builtin function or action expression (not a component).
    static func isBuiltin(_ name: String) -> Bool {
        allNames.contains(name)
    }

    // Positional parameter names of the built-in functions and steps, as upstream defines them.
    static let functionParams: [String: [String]] = [
        "Count": ["array"], "First": ["array"], "Last": ["array"],
        "Sum": ["numbers"], "Avg": ["numbers"], "Min": ["numbers"], "Max": ["numbers"],
        "Sort": ["array", "field", "direction"],
        "Filter": ["array", "field", "operator", "value"],
        "Round": ["number", "decimals"], "Abs": ["number"], "Floor": ["number"], "Ceil": ["number"],
        "Each": ["array", "varName", "template"]
    ]

    static let stepParams: [String: (params: [String], isLazy: Bool)] = [
        "Run": (["ref"], true),
        "ToAssistant": (["message", "context"], false),
        "OpenUrl": (["url"], false),
        "Set": (["variable", "value"], true),
        "Reset": (["variable"], true)
    ]

    /// The built-in functions, steps and `Action`: the base of every library's call registry.
    static let calls: [String: CallDef] = {
        var calls: [String: CallDef] = [:]
        for (name, params) in functionParams {
            calls[name] = CallDef(
                kind: .function,
                params: params.map { ParamDef(name: $0, required: false) },
                isBuiltin: true,
                isLazy: lazyNames.contains(name)
            )
        }
        for (name, step) in stepParams {
            calls[name] = CallDef(kind: .action, params: step.params.map { ParamDef(name: $0, required: false) }, isBuiltin: true, isLazy: step.isLazy)
        }
        calls["Action"] = CallDef(kind: .action, params: [ParamDef(name: "steps", required: true)], isBuiltin: true, isLazy: true)
        return calls
    }()

    /// Statement-level reserved calls.
    static let query = "Query"
    static let mutation = "Mutation"

    /// Whether `name` is a reserved statement call (`Query`, `Mutation`).
    static func isReservedCall(_ name: String) -> Bool {
        name == query || name == mutation
    }

    // MARK: - Implementations

    private static func argument(_ args: [OpenUIValue?], _ index: Int) -> OpenUIValue? {
        index < args.count ? args[index] : nil
    }

    /// Resolves a field path on a value. Supports dot paths: `"state.name"`.
    static func resolveField(_ value: OpenUIValue?, _ path: String) -> OpenUIValue? {
        if path.isEmpty || JS.isNullish(value) { return nil }
        if !path.contains(".") { return JS.property(of: value, key: path) }
        var current = value
        for part in path.split(separator: ".", omittingEmptySubsequences: false) {
            if JS.isNullish(current) { return nil }
            current = JS.property(of: current, key: String(part))
        }
        return current
    }

    private static func isNumericLike(_ value: OpenUIValue?) -> Bool {
        switch value {
        case .number?: return true
        case .string(let string)?: return !string.isEmpty && !JS.stringToNumber(string).isNaN
        default: return false
        }
    }

    private static func sort(_ args: [OpenUIValue?]) -> OpenUIValue {
        guard case .array(let items)? = argument(args, 0) else { return argument(args, 0) ?? .null }
        let fieldArgument = argument(args, 1)
        let field = JS.isNullish(fieldArgument) ? "" : JS.toString(fieldArgument)
        let directionArgument = argument(args, 2)
        let descending = (JS.isNullish(directionArgument) ? "asc" : JS.toString(directionArgument)) == "desc"

        func compare(_ a: OpenUIValue, _ b: OpenUIValue) -> Double {
            let av = field.isEmpty ? a : resolveField(a, field)
            let bv = field.isEmpty ? b : resolveField(b, field)
            if isNumericLike(av) && isNumericLike(bv) {
                let diff = JS.toNumber(av) - JS.toNumber(bv)
                return descending ? -diff : diff
            }
            let left = JS.isNullish(av) ? "" : JS.toString(av)
            let right = JS.isNullish(bv) ? "" : JS.toString(bv)
            let result: Double
            switch left.compare(right, locale: Locale.current) {
            case .orderedAscending: result = -1
            case .orderedDescending: result = 1
            case .orderedSame: result = 0
            }
            return descending ? -result : result
        }

        // Stable sort, like Array.prototype.sort.
        let sorted = items.enumerated().sorted { lhs, rhs in
            let order = compare(lhs.element, rhs.element)
            if order < 0 { return true }
            if order > 0 { return false }
            return lhs.offset < rhs.offset
        }
        return .array(sorted.map(\.element))
    }

    private static func filter(_ args: [OpenUIValue?]) -> OpenUIValue {
        guard case .array(let items)? = argument(args, 0) else { return .array([]) }
        let fieldArgument = argument(args, 1)
        let field = JS.isNullish(fieldArgument) ? "" : JS.toString(fieldArgument)
        let operatorArgument = argument(args, 2)
        let op = JS.isNullish(operatorArgument) ? "==" : JS.toString(operatorArgument)
        let target = argument(args, 3)

        return .array(items.filter { item in
            let value = field.isEmpty ? item : resolveField(item, field)
            switch op {
            case "==": return JS.looseEquals(value, target)
            case "!=": return !JS.looseEquals(value, target)
            case ">": return JS.toNumber(value) > JS.toNumber(target)
            case "<": return JS.toNumber(value) < JS.toNumber(target)
            case ">=": return JS.toNumber(value) >= JS.toNumber(target)
            case "<=": return JS.toNumber(value) <= JS.toNumber(target)
            case "contains":
                let haystack = JS.isNullish(value) ? "" : JS.toString(value)
                let needle = JS.isNullish(target) ? "" : JS.toString(target)
                // `String.prototype.includes` compares code units.
                return needle.isEmpty || haystack.range(of: needle, options: .literal) != nil
            default: return false
            }
        })
    }
}

/// Runtime action step type identifiers (match `ACTION_STEPS` values in the reference implementation).
@available(iOS 17.0, macOS 14.0, *)
enum ActionStepType {
    static let run = "run"
    static let continueConversation = "continue_conversation"
    static let openURL = "open_url"
    static let set = "set"
    static let reset = "reset"
    /// A step of one of the library's custom actions.
    static let customAction = "custom_action"
}
