//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Resolves runtime values for the evaluator.
@available(iOS 17.0, macOS 14.0, *)
struct EvaluationContext {
    /// Reads a `$variable` (`nil` = undefined).
    var getState: (String) -> OpenUIValue?
    /// Resolves a reference to another declaration's runtime value (query/mutation results, loop vars).
    var resolveRef: (String) -> OpenUIValue?
    /// Extra scope used when evaluating reactive setters (`$value`).
    var extraScope: [String: OpenUIValue]?
    /// The library's functions, called as `@Name(...)`.
    var functions: [String: OpenUIFunction]
    /// The library's custom actions, used as `@Name(...)` steps.
    var actions: [String: OpenUICustomAction]
    /// Reports a runtime error, such as a library function call that evaluated to null.
    var reportError: ((String) -> Void)?
    // Reports an error of one prop of an element, which `PropEvaluator` turns into `reportError`.
    var reportPropError: ((_ component: String, _ statementId: String?, _ prop: String, _ message: String) -> Void)?
    // Shared by every copy of this context, so one evaluation pass stops at the same bound.
    var budget = EvaluationBudget()

    init(
        getState: @escaping (String) -> OpenUIValue?,
        resolveRef: @escaping (String) -> OpenUIValue?,
        extraScope: [String: OpenUIValue]? = nil,
        functions: [String: OpenUIFunction] = [:],
        actions: [String: OpenUICustomAction] = [:],
        reportError: ((String) -> Void)? = nil
    ) {
        self.getState = getState
        self.resolveRef = resolveRef
        self.extraScope = extraScope
        self.functions = functions
        self.actions = actions
        self.reportError = reportError
    }
}

// How many nodes one evaluation pass may evaluate. Templates multiply, such as six nested `@Each`
// over ten items building a million elements, so past this they evaluate to nothing.
@available(iOS 17.0, macOS 14.0, *)
final class EvaluationBudget {
    static let maxNodes = 200_000

    private var remaining = maxNodes
    private var reported = false

    // Whether a node is left, reporting, once, when none is.
    func hasRemaining(reportError: ((String) -> Void)?) -> Bool {
        if remaining > 0 { return true }
        if !reported {
            reported = true
            reportError?("Evaluation stopped after \(Self.maxNodes) nodes: nest fewer @Each loops or loop over less data")
        }
        return false
    }

    func spend(reportError: ((String) -> Void)?) -> Bool {
        guard hasRemaining(reportError: reportError) else { return false }
        remaining -= 1
        return true
    }
}

/// Tells the evaluator which component props accept two-way `$variable` bindings.
@available(iOS 17.0, macOS 14.0, *)
protocol ReactivePropResolver {
    func isReactiveProp(component: String, prop: String) -> Bool
}

/// Reactive binding markers produced when a `$variable` is passed to a reactive prop
/// (`{ __reactive: "assign", target, expr }` in the reference implementation).
@available(iOS 17.0, macOS 14.0, *)
enum ReactiveBinding {
    static let markerKey = "__reactive"

    static func marker(target: String, expression: ASTNode) -> OpenUIValue {
        [markerKey: "assign", "target": .string(target), "expr": .expression(expression)]
    }

    /// Whether `value` is a reactive binding marker.
    static func isBinding(_ value: OpenUIValue?) -> Bool {
        guard case .object(let object)? = value else { return false }
        return object[markerKey] == .string("assign")
    }

    /// The bound `$variable` name.
    static func target(of value: OpenUIValue?) -> String? {
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
enum Evaluator {
    /// Evaluates an expression. Returns `nil` for JavaScript `undefined`.
    static func evaluate(_ node: ASTNode, _ context: EvaluationContext, _ schema: ReactivePropResolver? = nil) -> OpenUIValue? {
        guard context.budget.spend(reportError: context.reportError) else { return nil }
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

        case .comp(let name, let args, let mappedProps, _):
            // Built-ins coerce their args, so they skip validation. Lazy ones get them unevaluated.
            if Builtins.lazyNames.contains(name) {
                return evaluateLazyBuiltin(name, args, context, schema)
            }
            if let builtin = Builtins.definitionsByName[name] {
                let params = Builtins.functionParams[name] ?? []
                let named = mappedProps ?? Materializer.nameArgs(args, params.map { ParamDef(name: $0, required: false) })
                return builtin.function(params.map { param in named.first { $0.key == param }.flatMap { evaluate($0.value, context) } })
            }
            if Builtins.actionNames.contains(name) {
                return evaluateActionCall(name, args, mappedProps, context)
            }
            if let function = context.functions[name] {
                return callFunction(function, args, mappedProps, context)
            }
            if let action = context.actions[name] {
                return customActionPlan(action, args, mappedProps, context)
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
            var context = context
            if let reportPropError = context.reportPropError {
                context.reportError = { reportPropError(element.typeName, element.statementId, key, $0) }
            }
            let isReactive = schema.isReactiveProp(component: element.typeName, prop: key)
            props[key] = PropEvaluator.evaluateProp(value, context, schema, isReactive: isReactive) { child in
                evaluateElementInline(child, context, schema)
            }
        }
        evaluated.props = props
        return evaluated
    }

    // MARK: - Actions

    // MARK: - Library functions and custom actions

    /// A library function's or action's args by name. An explicit null for an optional param is
    /// left out, so its default applies.
    private static func callArgs(_ params: [PropField], _ args: [ASTNode], _ mappedProps: [ASTEntry]?, _ context: EvaluationContext) -> OpenUIObject {
        let named = mappedProps ?? Materializer.nameArgs(args, params.map { ParamDef(name: $0.name, required: false) })
        var result = OpenUIObject()
        for entry in named {
            let value = evaluate(entry.value, context)
            let isOptional = params.first { $0.name == entry.key }?.isOptional ?? true
            if JS.isNullish(value) && isOptional { continue }
            result[entry.key] = value ?? .null
        }
        return result
    }

    /// Whether a required arg without a default is missing, such as `@Percent($p)` with `$p` unset.
    private static func missesRequired(_ args: OpenUIObject, _ params: [PropField]) -> Bool {
        params.contains { param in
            !param.isOptional && JS.isNullish(args[param.name]) && param.defaultValue == nil
        }
    }

    /// Checks a value against a schema, reporting each problem. Returns `nil` when it is invalid,
    /// or, when `strict`, when anything was reported.
    private static func checkValue(_ value: OpenUIValue, _ schema: OpenUIValue, name: String, path: String, _ context: EvaluationContext, strict: Bool = false) -> OpenUIValue? {
        let validation = MaterializeContext(symbols: [:], catalog: nil, partial: false, currentStatementId: nil, unreached: nil)
        var checked = value
        let invalid = SchemaValidation.validate(&checked, schema: schema, component: name, path: path, context: validation)
        for error in validation.errors {
            context.reportError?("@\(name): \(error.message)")
        }
        if invalid || (strict && !validation.errors.isEmpty) { return nil }
        return checked
    }

    /// `@Percent(3, 4)` → the function's result for `part: 3, total: 4`; bad args or result, or a
    /// throw, give null.
    private static func callFunction(_ function: OpenUIFunction, _ args: [ASTNode], _ mappedProps: [ASTEntry]?, _ context: EvaluationContext) -> OpenUIValue {
        let raw = callArgs(function.params, args, mappedProps, context)
        if missesRequired(raw, function.params) { return .null }
        guard case .object(let checked)? = checkValue(.object(raw), function.paramsSchema, name: function.name, path: "", context) else {
            return .null
        }
        let result: OpenUIValue
        do {
            result = try function.implementation(checked)
        } catch {
            context.reportError?("@\(function.name) threw: \(error.localizedDescription)")
            return .null
        }
        guard let returns = function.returns else { return result }
        return checkValue(result, returns.jsonSchema, name: function.name, path: "/returns", context) ?? .null
    }

    /// A custom action call is a one-step plan. Any invalid arg gives an empty plan, a no-op, even an
    /// optional one with a default: an action never runs with a value the model didn't write.
    private static func customActionPlan(_ action: OpenUICustomAction, _ args: [ASTNode], _ mappedProps: [ASTEntry]?, _ context: EvaluationContext) -> OpenUIValue {
        let raw = callArgs(action.params, args, mappedProps, context)
        if missesRequired(raw, action.params) { return ActionPlan.empty }
        guard let params = checkValue(.object(raw), action.paramsSchema, name: action.name, path: "", context, strict: true) else {
            return ActionPlan.empty
        }
        return ActionPlan.plan([ActionPlan.customStep(name: action.name, params: params)])
    }

    // MARK: - Actions

    /// A step call is a one-step plan and an invalid step an empty plan; `Action([...])` flattens.
    private static func evaluateActionCall(_ name: String, _ args: [ASTNode], _ mappedProps: [ASTEntry]?, _ context: EvaluationContext) -> OpenUIValue {
        if name == "Action" {
            let list = args.isEmpty ? .array([]) : evaluate(args[0], context)
            return ActionPlan.flatten(list?.arrayValue ?? [])
        }
        let step: OpenUIValue?
        switch name {
        case "Run":
            if let first = args.first, case .runtimeRef(let statementId, let refType) = first {
                step = ["type": .string(ActionStepType.run), "statementId": .string(statementId), "refType": .string(refType.rawValue)]
            } else {
                step = nil
            }
        case "ToAssistant":
            let named = stepArgs(name, args, mappedProps, context)
            var object: OpenUIObject = ["type": .string(ActionStepType.continueConversation), "message": .string(stringValue(named["message"]))]
            // The context may be any value and is passed through unchanged; null means none.
            if let assistantContext = named["context"], !JS.isNullish(assistantContext) {
                object["context"] = assistantContext
            }
            step = .object(object)
        case "OpenUrl":
            let named = stepArgs(name, args, mappedProps, context)
            step = ["type": .string(ActionStepType.openURL), "url": .string(stringValue(named["url"]))]
        case "Set":
            if args.count >= 2, case .stateRef(let target) = args[0] {
                step = ["type": .string(ActionStepType.set), "target": .string(target), "valueAST": .expression(args[1])]
            } else {
                step = nil
            }
        case "Reset":
            let targets: [OpenUIValue] = args.compactMap { arg in
                if case .stateRef(let name) = arg { return .string(name) }
                return nil
            }
            step = targets.isEmpty ? nil : ["type": .string(ActionStepType.reset), "targets": .array(targets)]
        default:
            step = nil
        }
        return ActionPlan.plan(step.map { [$0] } ?? [])
    }

    private static func stepArgs(_ name: String, _ args: [ASTNode], _ mappedProps: [ASTEntry]?, _ context: EvaluationContext) -> OpenUIObject {
        let params = (Builtins.stepParams[name]?.params ?? []).map { ParamDef(name: $0, required: false) }
        var result = OpenUIObject()
        for entry in mappedProps ?? Materializer.nameArgs(args, params) {
            result[entry.key] = evaluate(entry.value, context) ?? .null
        }
        return result
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

        var results: [OpenUIValue] = []
        for item in items {
            guard context.budget.hasRemaining(reportError: context.reportError) else { break }
            let substituted = substituteRef(template, variableName, item)
            var childContext = context
            let parentResolve = context.resolveRef
            childContext.resolveRef = { refName in
                refName == variableName ? item : parentResolve(refName)
            }
            let result = evaluate(substituted, childContext, schema)
            if let schema, case .element(let element)? = result {
                results.append(.element(evaluateElementInline(element, childContext, schema)))
            } else {
                results.append(result ?? .null)
            }
        }
        return .array(results)
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
        case .comp(let name, let args, let mappedProps, let isFunction):
            // An inner `@Each` with the same loop variable shadows this one in its template.
            if Builtins.lazyNames.contains(name), args.count >= 3, args[1] == .ref(variableName) || args[1] == .str(variableName) {
                return .comp(
                    name: name,
                    args: args.enumerated().map { index, arg in index == 0 ? substituteRef(arg, variableName, value) : arg },
                    mappedProps: mappedProps,
                    isFunction: isFunction
                )
            }
            return .comp(
                name: name,
                args: args.map { substituteRef($0, variableName, value) },
                mappedProps: mappedProps?.map { ASTEntry($0.key, substituteRef($0.value, variableName, value)) },
                isFunction: isFunction
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
enum PropEvaluator {
    /// Evaluates `root`, or the component a runtime entry (`root = $t ? A : B`) picks, with the
    /// runtime errors evaluation reports (upstream `evaluateRoot`).
    static func evaluateRoot(_ result: ParseResult?, _ context: EvaluationContext, _ schema: ReactivePropResolver) -> (root: ElementNode?, errors: [OpenUIError]) {
        let collector = RuntimeErrorCollector()
        var context = context
        context.reportPropError = { component, statementId, prop, message in
            collector.errors.append(OpenUIError(
                source: .runtime,
                code: "runtime-error",
                message: "Evaluating prop \"\(prop)\" on \(component) failed: \(message)",
                statementId: statementId,
                component: component,
                hint: "Check the expression used for prop \"\(prop)\""
            ))
        }
        if let root = result?.root {
            return (evaluateElementProps(root, context, schema), collector.errors)
        }
        guard let rootExpression = result?.rootExpression else { return (nil, collector.errors) }
        if case .element(let element)? = Evaluator.evaluate(rootExpression, context, schema) {
            return (evaluateElementProps(element, context, schema), collector.errors)
        }
        collector.errors.append(OpenUIError(source: .runtime, code: "no-root", message: "root does not evaluate to a component", statementId: "root"))
        return (nil, collector.errors)
    }

    /// Evaluates every dynamic prop of an element tree into concrete values.
    static func evaluateElementProps(_ element: ElementNode, _ context: EvaluationContext, _ schema: ReactivePropResolver) -> ElementNode {
        if element.hasDynamicProps == false { return element }
        var evaluated = element
        var props = OpenUIObject()
        for (key, value) in element.props.entries {
            var context = context
            if let reportPropError = context.reportPropError {
                context.reportError = { reportPropError(element.typeName, element.statementId, key, $0) }
            }
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
        let result = evaluatePropValue(value, context, schema, isReactive: isReactive, recurseElement: recurseElement)
        // Only real calls make custom steps: a plan read from data loses them.
        return ActionPlan.isPlan(result) ? result.map(ActionPlan.ownSteps) : result
    }

    private static func evaluatePropValue(
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
            // Action plans are preserved for deferred (click-time) evaluation.
            if case .array? = object["steps"] { return value }
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

@available(iOS 17.0, macOS 14.0, *)
private final class RuntimeErrorCollector {
    var errors: [OpenUIError] = []
}
