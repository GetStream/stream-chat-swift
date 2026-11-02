//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Resolves runtime values for the evaluator.
@available(iOS 17.0, macOS 14.0, *)
public struct EvaluationContext {
    /// Reads a `$variable` (`nil` = undefined).
    public var getState: (String) -> OpenUIValue?
    /// Resolves a reference to another declaration's runtime value (query/mutation results, loop vars).
    public var resolveRef: (String) -> OpenUIValue?
    /// Extra scope used when evaluating reactive setters (`$value`).
    public var extraScope: [String: OpenUIValue]?

    public init(
        getState: @escaping (String) -> OpenUIValue?,
        resolveRef: @escaping (String) -> OpenUIValue?,
        extraScope: [String: OpenUIValue]? = nil
    ) {
        self.getState = getState
        self.resolveRef = resolveRef
        self.extraScope = extraScope
    }
}

/// Tells the evaluator which component props accept two-way `$variable` bindings.
@available(iOS 17.0, macOS 14.0, *)
public protocol ReactivePropResolver {
    func isReactiveProp(component: String, prop: String) -> Bool
}

/// Reactive binding markers produced when a `$variable` is passed to a reactive prop
/// (`{ __reactive: "assign", target, expr }` in the reference implementation).
@available(iOS 17.0, macOS 14.0, *)
public enum ReactiveBinding {
    static let markerKey = "__reactive"

    static func marker(target: String, expression: ASTNode) -> OpenUIValue {
        [markerKey: "assign", "target": .string(target), "expr": .expression(expression)]
    }

    /// Whether `value` is a reactive binding marker.
    public static func isBinding(_ value: OpenUIValue?) -> Bool {
        guard case .object(let object)? = value else { return false }
        return object[markerKey] == .string("assign")
    }

    /// The bound `$variable` name.
    public static func target(of value: OpenUIValue?) -> String? {
        guard isBinding(value) else { return nil }
        return value?["target"]?.stringValue
    }

    /// The setter expression of a binding. Nested markers (produced by repeated prop evaluation)
    /// are unwrapped to the innermost expression.
    static func expression(of value: OpenUIValue?) -> ASTNode? {
        var current = value?["expr"]
        while let candidate = current {
            if case .expression(let node) = candidate { return node }
            guard isBinding(candidate) else { return nil }
            current = candidate["expr"]
        }
        return nil
    }
}

/// Evaluates AST nodes to runtime values with JavaScript semantics (port of `evaluator.ts`).
@available(iOS 17.0, macOS 14.0, *)
public enum Evaluator {
    /// Evaluates an expression. Returns `nil` for JavaScript `undefined`.
    public static func evaluate(_ node: ASTNode, _ context: EvaluationContext, _ schema: ReactivePropResolver? = nil) -> OpenUIValue? {
        switch node {
        case .str(let value):
            return .string(value)
        case .num(let value):
            return .number(value)
        case .bool(let value):
            return .bool(value)
        case .null, .placeholder:
            return .null

        case .stateRef(let name):
            if let scoped = context.extraScope?[name], !JS.isNullish(scoped) { return scoped }
            return context.getState(name)

        case .ref(let name), .runtimeRef(let name, _):
            return context.resolveRef(name)

        case .arr(let elements):
            return .array(elements.map { evaluate($0, context) ?? .null })

        case .obj(let entries):
            var object = OpenUIObject()
            for entry in entries {
                object[entry.key] = evaluate(entry.value, context)
            }
            return .object(object)

        case .comp(let name, let args, let mappedProps):
            if Builtins.lazyNames.contains(name) {
                return evaluateLazyBuiltin(name, args, context, schema)
            }
            if let builtin = Builtins.definitionsByName[name] {
                return builtin.function(args.map { evaluate($0, context) })
            }
            if Builtins.actionNames.contains(name) {
                return evaluateActionCall(name, args, context)
            }
            guard let mappedProps else {
                // After materialization only builtins and mapped catalog calls reach here.
                return .null
            }
            return evaluateMappedComponent(name, mappedProps, context, schema)

        case .binary(let op, let leftNode, let rightNode):
            if op == "&&" {
                let left = evaluate(leftNode, context)
                return JS.isTruthy(left) ? evaluate(rightNode, context) : left
            }
            if op == "||" {
                let left = evaluate(leftNode, context)
                return JS.isTruthy(left) ? left : evaluate(rightNode, context)
            }
            let left = evaluate(leftNode, context)
            let right = evaluate(rightNode, context)
            switch op {
            case "+":
                if JS.typeOf(left) == "string" || JS.typeOf(right) == "string" {
                    let lhs = JS.isNullish(left) ? "" : JS.toString(left)
                    let rhs = JS.isNullish(right) ? "" : JS.toString(right)
                    return .string(lhs + rhs)
                }
                return .number(JS.toNumber(left) + JS.toNumber(right))
            case "-":
                return .number(JS.toNumber(left) - JS.toNumber(right))
            case "*":
                return .number(JS.toNumber(left) * JS.toNumber(right))
            case "/":
                // DSL choice: division by zero yields 0 instead of Infinity/NaN.
                let divisor = JS.toNumber(right)
                return .number(divisor == 0 ? 0 : JS.toNumber(left) / divisor)
            case "%":
                let divisor = JS.toNumber(right)
                return .number(divisor == 0 ? 0 : JS.toNumber(left).truncatingRemainder(dividingBy: divisor))
            case "==":
                return .bool(JS.looseEquals(left, right))
            case "!=":
                return .bool(!JS.looseEquals(left, right))
            case ">":
                return .bool(JS.toNumber(left) > JS.toNumber(right))
            case "<":
                return .bool(JS.toNumber(left) < JS.toNumber(right))
            case ">=":
                return .bool(JS.toNumber(left) >= JS.toNumber(right))
            case "<=":
                return .bool(JS.toNumber(left) <= JS.toNumber(right))
            default:
                return .null
            }

        case .unary(let op, let operand):
            if op == "!" { return .bool(!JS.isTruthy(evaluate(operand, context))) }
            if op == "-" { return .number(-JS.toNumber(evaluate(operand, context))) }
            return .null

        case .ternary(let condition, let then, let otherwise):
            return JS.isTruthy(evaluate(condition, context)) ? evaluate(then, context) : evaluate(otherwise, context)

        case .member(let objectNode, let field):
            let object = evaluate(objectNode, context)
            if JS.isNullish(object) { return .null }
            if case .array(let items)? = object {
                // Array pluck: extract the field from every element.
                if field == "length" { return .number(Double(items.count)) }
                return .array(items.map { item in
                    let value = JS.property(of: item, key: field)
                    return JS.isNullish(value) ? .null : value!
                })
            }
            return JS.property(of: object, key: field)

        case .index(let objectNode, let indexNode):
            let object = evaluate(objectNode, context)
            let index = evaluate(indexNode, context)
            if JS.isNullish(object) || JS.isNullish(index) { return .null }
            if case .array(let items)? = object {
                let position = JS.toNumber(index)
                guard position.isFinite, position == position.rounded(), position >= 0, position < Double(items.count) else { return nil }
                return items[Int(position)]
            }
            return JS.property(of: object, key: JS.toString(index))

        case .assign(let target, let value):
            return ReactiveBinding.marker(target: target, expression: value)
        }
    }

    /// A catalog component call inside an expression (e.g. a ternary branch or `@Each` template).
    private static func evaluateMappedComponent(_ name: String, _ mappedProps: [ASTEntry], _ context: EvaluationContext, _ schema: ReactivePropResolver?) -> OpenUIValue {
        var props = OpenUIObject()
        for entry in mappedProps {
            let isReactive = schema?.isReactiveProp(component: name, prop: entry.key) ?? false
            if case .stateRef(let stateName) = entry.value {
                if isReactive {
                    props[entry.key] = ReactiveBinding.marker(target: stateName, expression: .stateRef("$value"))
                } else if schema != nil {
                    props[entry.key] = context.getState(stateName)
                } else {
                    // Without schema context, preserve the reference for prop evaluation.
                    props[entry.key] = .expression(entry.value)
                }
            } else {
                props[entry.key] = evaluate(entry.value, context, schema)
            }
        }
        var element = ElementNode(typeName: name, props: props, partial: false, hasDynamicProps: true)
        if let schema {
            for (key, value) in props.entries {
                switch value {
                case .element(let child):
                    element.props[key] = .element(evaluateElementInline(child, context, schema))
                case .array(let items):
                    element.props[key] = .array(items.map { item in
                        if case .element(let child) = item {
                            return .element(evaluateElementInline(child, context, schema))
                        }
                        return item
                    })
                default:
                    break
                }
            }
        }
        return .element(element)
    }

    /// Evaluates an element's props with reactive awareness (inline evaluation path).
    static func evaluateElementInline(_ element: ElementNode, _ context: EvaluationContext, _ schema: ReactivePropResolver) -> ElementNode {
        if element.hasDynamicProps == false { return element }
        var evaluated = element
        var props = OpenUIObject()
        for (key, value) in element.props.entries {
            let isReactive = schema.isReactiveProp(component: element.typeName, prop: key)
            props[key] = PropEvaluator.evaluateProp(value, context, schema, isReactive: isReactive) { child in
                evaluateElementInline(child, context, schema)
            }
        }
        evaluated.props = props
        return evaluated
    }

    // MARK: - Actions

    private static func evaluateActionCall(_ name: String, _ args: [ASTNode], _ context: EvaluationContext) -> OpenUIValue {
        switch name {
        case "Action":
            let stepsArgument = args.isEmpty ? .array([]) : evaluate(args[0], context)
            guard case .array(let rawSteps)? = stepsArgument else { return ["steps": .array([])] }
            let steps = rawSteps.filter { step in
                switch step {
                case .object(let object): return object.contains("type")
                case .element: return true
                default: return false
                }
            }
            return ["steps": .array(steps)]

        case "Run":
            guard let first = args.first, case .runtimeRef(let statementId, let refType) = first else { return .null }
            return ["type": .string(ActionStepType.run), "statementId": .string(statementId), "refType": .string(refType.rawValue)]

        case "ToAssistant":
            let message = args.isEmpty ? "" : stringValue(evaluate(args[0], context))
            var step: OpenUIObject = ["type": .string(ActionStepType.continueConversation), "message": .string(message)]
            if args.count > 1 {
                step["context"] = .string(stringValue(evaluate(args[1], context)))
            }
            return .object(step)

        case "OpenUrl":
            let url = args.isEmpty ? "" : stringValue(evaluate(args[0], context))
            return ["type": .string(ActionStepType.openURL), "url": .string(url)]

        case "Set":
            guard args.count >= 2, case .stateRef(let target) = args[0] else { return .null }
            return ["type": .string(ActionStepType.set), "target": .string(target), "valueAST": .expression(args[1])]

        case "Reset":
            let targets: [OpenUIValue] = args.compactMap { arg in
                if case .stateRef(let name) = arg { return .string(name) }
                return nil
            }
            guard !targets.isEmpty else { return .null }
            return ["type": .string(ActionStepType.reset), "targets": .array(targets)]

        default:
            return .null
        }
    }

    /// `String(value ?? "")`
    private static func stringValue(_ value: OpenUIValue?) -> String {
        JS.isNullish(value) ? "" : JS.toString(value)
    }

    // MARK: - Lazy builtins

    /// `@Each(array, varName, template)` — evaluates the template once per item. Loop variable
    /// references are substituted with literal values first so deferred expressions (like action
    /// steps evaluated at click time) capture concrete values.
    private static func evaluateLazyBuiltin(_ name: String, _ args: [ASTNode], _ context: EvaluationContext, _ schema: ReactivePropResolver?) -> OpenUIValue {
        guard name == "Each" else { return .null }
        guard args.count >= 3 else { return .array([]) }
        guard case .array(let items)? = evaluate(args[0], context) else { return .array([]) }
        let variableName: String
        switch args[1] {
        case .ref(let ref): variableName = ref
        case .str(let string): variableName = string
        default: return .array([])
        }
        guard !variableName.isEmpty else { return .array([]) }
        let template = args[2]

        return .array(items.map { item in
            let substituted = substituteRef(template, variableName, item)
            var childContext = context
            let parentResolve = context.resolveRef
            childContext.resolveRef = { refName in
                refName == variableName ? item : parentResolve(refName)
            }
            let result = evaluate(substituted, childContext, schema)
            if let schema, case .element(let element)? = result {
                return .element(evaluateElementInline(element, childContext, schema))
            }
            return result ?? .null
        })
    }

    /// Converts a runtime value back into a literal AST node.
    static func literalAST(_ value: OpenUIValue?) -> ASTNode {
        guard let value else { return .null }
        switch value {
        case .null: return .null
        case .string(let string): return .str(string)
        case .number(let number): return .num(number)
        case .bool(let bool): return .bool(bool)
        case .array(let items): return .arr(items.map(literalAST))
        case .object(let object): return .obj(object.entries.map { ASTEntry($0.key, literalAST($0.value)) })
        case .element(let element): return literalAST(element.jsonValue)
        case .expression(let node): return literalAST(node.jsonValue)
        }
    }

    /// Replaces every `Ref(variableName)` in `node` with the literal form of `value`.
    static func substituteRef(_ node: ASTNode, _ variableName: String, _ value: OpenUIValue) -> ASTNode {
        switch node {
        case .ref(let name):
            return name == variableName ? literalAST(value) : node
        case .member(let object, let field):
            let substituted = substituteRef(object, variableName, value)
            if case .obj(let entries) = substituted, let entry = entries.first(where: { $0.key == field }) {
                return entry.value
            }
            return .member(substituted, field)
        case .index(let object, let index):
            return .index(substituteRef(object, variableName, value), substituteRef(index, variableName, value))
        case .binary(let op, let left, let right):
            return .binary(op, substituteRef(left, variableName, value), substituteRef(right, variableName, value))
        case .unary(let op, let operand):
            return .unary(op, substituteRef(operand, variableName, value))
        case .ternary(let condition, let then, let otherwise):
            return .ternary(
                substituteRef(condition, variableName, value),
                substituteRef(then, variableName, value),
                substituteRef(otherwise, variableName, value)
            )
        case .arr(let elements):
            return .arr(elements.map { substituteRef($0, variableName, value) })
        case .obj(let entries):
            return .obj(entries.map { ASTEntry($0.key, substituteRef($0.value, variableName, value)) })
        case .comp(let name, let args, let mappedProps):
            return .comp(
                name: name,
                args: args.map { substituteRef($0, variableName, value) },
                mappedProps: mappedProps?.map { ASTEntry($0.key, substituteRef($0.value, variableName, value)) }
            )
        case .assign(let target, let expression):
            return .assign(target, substituteRef(expression, variableName, value))
        case .str, .num, .bool, .null, .placeholder, .stateRef, .runtimeRef:
            return node
        }
    }
}

/// Prop evaluation shared by the inline and tree paths (port of `evaluate-prop.ts` / `evaluate-tree.ts`).
@available(iOS 17.0, macOS 14.0, *)
public enum PropEvaluator {
    /// Evaluates every dynamic prop of an element tree into concrete values.
    public static func evaluateElementProps(_ element: ElementNode, _ context: EvaluationContext, _ schema: ReactivePropResolver) -> ElementNode {
        if element.hasDynamicProps == false { return element }
        var evaluated = element
        var props = OpenUIObject()
        for (key, value) in element.props.entries {
            let isReactive = schema.isReactiveProp(component: element.typeName, prop: key)
            props[key] = evaluateProp(value, context, schema, isReactive: isReactive) { child in
                evaluateElementProps(child, context, schema)
            }
        }
        evaluated.props = props
        return evaluated
    }

    /// Evaluates a single prop value: AST nodes are resolved (or turned into reactive binding markers),
    /// nested elements recurse, action plans are preserved for click-time evaluation.
    static func evaluateProp(
        _ value: OpenUIValue?,
        _ context: EvaluationContext,
        _ schema: ReactivePropResolver,
        isReactive: Bool,
        recurseElement: (ElementNode) -> ElementNode
    ) -> OpenUIValue? {
        guard let value else { return nil }
        switch value {
        case .null, .bool, .number, .string:
            return value

        case .expression(let node):
            if isReactive, case .stateRef(let name) = node {
                return ReactiveBinding.marker(target: name, expression: .stateRef("$value"))
            }
            let result = Evaluator.evaluate(node, context, schema)
            switch result {
            case .element(let element)?:
                return .element(recurseElement(element))
            case .array(let items)?:
                return .array(items.map { item in
                    if case .element(let element) = item { return .element(recurseElement(element)) }
                    return item
                })
            default:
                if !isReactive, let target = ReactiveBinding.target(of: result) {
                    // Strip binding markers from non-reactive props: use the current value.
                    let current = context.getState(target)
                    return JS.isNullish(current) ? .null : current
                }
                return result
            }

        case .array(let items):
            return .array(items.map { evaluateProp($0, context, schema, isReactive: isReactive, recurseElement: recurseElement) ?? .null })

        case .element(let element):
            return .element(recurseElement(element))

        case .object(let object):
            // Action plans / steps are preserved for deferred (click-time) evaluation.
            if case .array? = object["steps"] { return value }
            if object.contains("type") && object.contains("valueAST") { return value }
            let needsEvaluation = object.values.contains { nested in
                switch nested {
                case .array, .object, .element, .expression: return true
                default: return false
                }
            }
            guard needsEvaluation else { return value }
            var result = OpenUIObject()
            for (key, nested) in object.entries {
                result[key] = evaluateProp(nested, context, schema, isReactive: isReactive, recurseElement: recurseElement)
            }
            return .object(result)
        }
    }
}
