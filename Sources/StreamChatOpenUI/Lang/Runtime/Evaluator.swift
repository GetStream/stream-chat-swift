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
    // The items of the `@Each` loops being evaluated, by their variable names.
    var loopItems: [String: OpenUIValue] = [:]

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
// over ten items building a million elements, so past this they evaluate to nothing. Work that
// walks a value, such as comparing an array or rebuilding an `@Each` template for each item,
// counts as the nodes it walks.
@available(iOS 17.0, macOS 14.0, *)
final class EvaluationBudget {
    static let maxNodes = 200_000
    // How deep components may nest in what is evaluated. The parser takes deeper programs, but
    // each level takes stack: in Debug builds about 11 KB, so the main thread's 1 MB runs out at
    // about ninety.
    static let maxDepth = 48

    private var remaining = maxNodes
    private var reported = false
    private var depth = 0
    private var reportedDepth = false

    var remainingNodes: Int { max(remaining, 0) }

    // Whether the pass ran out, so what it evaluated since is incomplete.
    var ranOut: Bool { reported }

    // Whether a node is left, reporting, once, when none is.
    func hasRemaining(reportError: ((String) -> Void)?) -> Bool {
        if remaining > 0 { return true }
        if !reported {
            reported = true
            reportError?("Evaluation stopped after \(Self.maxNodes) nodes: nest fewer @Each loops or loop over less data")
        }
        return false
    }

    func spend(_ count: Int = 1, reportError: ((String) -> Void)?) -> Bool {
        guard hasRemaining(reportError: reportError) else { return false }
        guard count <= remaining else {
            remaining = 0
            return hasRemaining(reportError: reportError)
        }
        remaining -= count
        return true
    }

    // Enters one more level of components, reporting, once, when it is too deep. Every `enter`
    // that returns true needs a `leave`.
    func enter(reportError: ((String) -> Void)?) -> Bool {
        guard depth < Self.maxDepth else {
            if !reportedDepth {
                reportedDepth = true
                reportError?("Evaluation stopped at \(Self.maxDepth) levels of nesting: nest fewer components")
            }
            return false
        }
        depth += 1
        return true
    }

    func leave() {
        depth -= 1
    }

    // The nodes of `value` walking it visits, counting up to `limit`. Scalars cost nothing. A node
    // counts when it is found, so the walk stops at `limit` however wide the value is.
    static func size(of value: OpenUIValue?, limit: Int) -> Int {
        guard let value, value.isContainer, limit > 0 else { return 0 }
        var count = 1
        var pending = [value]
        func visit(_ child: OpenUIValue) -> Bool {
            count += 1
            if child.isContainer { pending.append(child) }
            return count < limit
        }
        walk: while count < limit, let next = pending.popLast() {
            switch next {
            case .array(let items):
                for item in items {
                    guard visit(item) else { break walk }
                }
            case .object(let object):
                for key in object.keys {
                    guard let item = object[key] else { continue }
                    guard visit(item) else { break walk }
                }
            case .element(let element):
                guard visit(.object(element.props)) else { break walk }
            case .null, .bool, .number, .string, .expression:
                break
            }
        }
        return min(count, limit)
    }
}

@available(iOS 17.0, macOS 14.0, *)
private extension OpenUIValue {
    var isContainer: Bool {
        switch self {
        case .array, .object, .element: return true
        case .null, .bool, .number, .string, .expression: return false
        }
    }

    // Whether a component is in the value, at any depth.
    var containsElement: Bool {
        var pending = [self]
        while let next = pending.popLast() {
            switch next {
            case .element:
                return true
            case .array(let items):
                pending.append(contentsOf: items)
            case .object(let object):
                pending.append(contentsOf: object.values)
            case .null, .bool, .number, .string, .expression:
                continue
            }
        }
        return false
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
                let values = params.map { param in named.first { $0.key == param }.flatMap { evaluate($0.value, context) } }
                guard spendWork(ofBuiltin: name, values, context) else { return nil }
                return builtin.function(values)
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
            guard spendCoercion(of: left, right, context) else { return nil }
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
            return memberValue(evaluate(objectNode, context), field, context)

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

    // Spends what coercing or comparing the operands walks: arrays and objects, which a string,
    // number or `==` turns into text or compares field by field.
    private static func spendCoercion(of left: OpenUIValue?, _ right: OpenUIValue?, _ context: EvaluationContext) -> Bool {
        let limit = context.budget.remainingNodes + 1
        let cost = EvaluationBudget.size(of: left, limit: limit) + EvaluationBudget.size(of: right, limit: limit)
        return cost == 0 || context.budget.spend(cost, reportError: context.reportError)
    }

    private static let builtinsWalkingItems: Set<String> = ["Sum", "Avg", "Min", "Max", "Filter", "Sort"]

    // Spends what a builtin that walks an array does, before it runs, so one past the budget
    // doesn't: a node for each item, or for `@Sort` each comparison, whatever the items are, and
    // the nodes of the arrays and objects `@Filter` and `@Sort` compare, with `@Filter`'s target
    // compared with every item.
    private static func spendWork(ofBuiltin name: String, _ values: [OpenUIValue?], _ context: EvaluationContext) -> Bool {
        guard builtinsWalkingItems.contains(name), case .array(let items)? = values.first ?? nil else { return true }
        let isSort = name == "Sort"
        // A sort compares each item about log2(n) times.
        let comparisons = isSort ? max(1, Int.bitWidth - items.count.leadingZeroBitCount) : 1
        guard context.budget.spend(saturatingProduct(items.count, comparisons), reportError: context.reportError) else { return false }
        guard isSort || name == "Filter" else { return true }
        let fieldValue = values.count > 1 ? values[1] : nil
        let field = JS.isNullish(fieldValue) ? "" : JS.toString(fieldValue)
        let limit = context.budget.remainingNodes + 1
        var walked = 0
        for item in items {
            walked += EvaluationBudget.size(of: field.isEmpty ? item : Builtins.resolveField(item, field), limit: limit)
            if walked >= limit { break }
        }
        var cost = saturatingProduct(walked, comparisons)
        if !isSort, values.count > 3 {
            cost = saturatingSum(cost, saturatingProduct(EvaluationBudget.size(of: values[3], limit: limit), items.count))
        }
        return cost == 0 || context.budget.spend(cost, reportError: context.reportError)
    }

    private static func saturatingProduct(_ lhs: Int, _ rhs: Int) -> Int {
        let (product, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        return overflow ? Int.max / 2 : product
    }

    private static func saturatingSum(_ lhs: Int, _ rhs: Int) -> Int {
        let (sum, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? Int.max / 2 : sum
    }

    /// A catalog component call inside an expression (e.g. a ternary branch or `@Each` template).
    private static func evaluateMappedComponent(_ name: String, _ mappedProps: [ASTEntry], _ context: EvaluationContext, _ schema: ReactivePropResolver?) -> OpenUIValue {
        // Its props can call components of their own, so it is a level of nesting before they
        // are evaluated.
        guard context.budget.enter(reportError: context.reportError) else {
            return .element(ElementNode(typeName: name, hasDynamicProps: false))
        }
        defer { context.budget.leave() }
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
        guard context.budget.enter(reportError: context.reportError) else { return element.withoutProps }
        defer { context.budget.leave() }
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
                step = ["type": .string(ActionStepType.set), "target": .string(target), "valueAST": .expression(capturingLoopItems(args[1], context))]
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

    // A `@Set` value is evaluated when it is tapped, outside its `@Each`, so it keeps the values of
    // the loop items it reads, even the parts a template keeps as references for their components.
    private static func capturingLoopItems(_ node: ASTNode, _ context: EvaluationContext) -> ASTNode {
        context.loopItems.reduce(node) { captured, loop in
            LoopSubstitution(variableName: loop.key, item: loop.value, keepsComponents: false, context: context).apply(captured)
        }
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
        // A template that doesn't read the item is the same for each, and one that does is
        // rebuilt for each, which costs its size.
        var templateSize = 0
        var readsItem = false
        template.walk { node in
            templateSize += 1
            if case .ref(let name) = node, name == variableName { readsItem = true }
        }

        var results: [OpenUIValue] = []
        for item in items {
            guard context.budget.hasRemaining(reportError: context.reportError) else { break }
            if readsItem {
                guard context.budget.spend(templateSize, reportError: context.reportError) else { break }
            }
            let substituted = readsItem
                ? LoopSubstitution(variableName: variableName, item: item, keepsComponents: true, context: context).apply(template)
                : template
            var childContext = context
            let parentResolve = context.resolveRef
            childContext.resolveRef = { refName in
                refName == variableName ? item : parentResolve(refName)
            }
            childContext.loopItems[variableName] = item
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

    // `object.field`, spending a node for each item an array plucks the field from.
    static func memberValue(_ object: OpenUIValue?, _ field: String, _ context: EvaluationContext) -> OpenUIValue? {
        if case .array(let items)? = object, field != "length" {
            guard context.budget.spend(items.count, reportError: context.reportError) else { return nil }
        }
        return memberValue(object, field)
    }

    // `object.field`: an array plucks the field from each of its items.
    private static func memberValue(_ object: OpenUIValue?, _ field: String) -> OpenUIValue? {
        if JS.isNullish(object) { return .null }
        if case .array(let items)? = object {
            if field == "length" { return .number(Double(items.count)) }
            return .array(items.map { item in
                let value = JS.property(of: item, key: field)
                return JS.isNullish(value) ? .null : value!
            })
        }
        return JS.property(of: object, key: field)
    }
}

// Puts a loop item in place of its variable in an `@Each` template, as literals, so deferred
// expressions, such as steps that run when tapped, keep the item's values. A field path, such as
// `item.label`, is read before it becomes a literal, so it doesn't copy the rest of the item, and
// what becomes a literal is spent, as the template rebuilds it for each item.
@available(iOS 17.0, macOS 14.0, *)
private struct LoopSubstitution {
    let variableName: String
    let item: OpenUIValue
    // Whether a part of the item that holds a component stays a reference, which the item's
    // context resolves: as a literal, the component would be a plain object no view draws.
    let keepsComponents: Bool
    let context: EvaluationContext

    // `readsPath` is false for the object of a field access that isn't a path of the variable,
    // whose own object then isn't either.
    func apply(_ node: ASTNode, readsPath: Bool = true) -> ASTNode {
        switch node {
        case .ref(let name):
            return name == variableName ? literal(item, orKeeping: node) : node
        case .member(let object, let field):
            var objectIsPath = false
            if readsPath {
                let reached = read(node)
                if reached.isPath, let part = reached.value {
                    return literal(part, orKeeping: node)
                }
                objectIsPath = reached.isPath
            }
            let substituted = apply(object, readsPath: objectIsPath)
            if case .obj(let entries) = substituted, let entry = entries.first(where: { $0.key == field }) {
                return entry.value
            }
            return .member(substituted, field)
        case .index(let object, let index):
            return .index(apply(object), apply(index))
        case .binary(let op, let left, let right):
            return .binary(op, apply(left), apply(right))
        case .unary(let op, let operand):
            return .unary(op, apply(operand))
        case .ternary(let condition, let then, let otherwise):
            return .ternary(apply(condition), apply(then), apply(otherwise))
        case .arr(let elements):
            return .arr(elements.map { apply($0) })
        case .obj(let entries):
            return .obj(entries.map { ASTEntry($0.key, apply($0.value)) })
        case .comp(let name, let args, let mappedProps, let isFunction):
            // An inner `@Each` with the same loop variable shadows this one in its template.
            if Builtins.lazyNames.contains(name), args.count >= 3, args[1] == .ref(variableName) || args[1] == .str(variableName) {
                return .comp(
                    name: name,
                    args: args.enumerated().map { index, arg in index == 0 ? apply(arg) : arg },
                    mappedProps: mappedProps,
                    isFunction: isFunction
                )
            }
            return .comp(
                name: name,
                args: args.map { apply($0) },
                mappedProps: mappedProps?.map { ASTEntry($0.key, apply($0.value)) },
                isFunction: isFunction
            )
        case .assign(let target, let expression):
            return .assign(target, apply(expression))
        case .str, .num, .bool, .null, .placeholder, .stateRef, .runtimeRef:
            return node
        }
    }

    // Whether `node` is the variable or a field path of it, and the value it reads, which is
    // `nil` when its last field is missing.
    private func read(_ node: ASTNode) -> (isPath: Bool, value: OpenUIValue?) {
        switch node {
        case .ref(let name):
            return (name == variableName, item)
        case .member(let object, let field):
            let base = read(object)
            return base.isPath ? (true, Evaluator.memberValue(base.value, field, context)) : (false, nil)
        default:
            return (false, nil)
        }
    }

    private func literal(_ part: OpenUIValue, orKeeping node: ASTNode) -> ASTNode {
        let size = EvaluationBudget.size(of: part, limit: context.budget.remainingNodes + 1)
        guard context.budget.spend(size, reportError: context.reportError) else { return .null }
        return keepsComponents && part.containsElement ? node : Evaluator.literalAST(part)
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
        guard context.budget.enter(reportError: context.reportError) else { return element.withoutProps }
        defer { context.budget.leave() }
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

@available(iOS 17.0, macOS 14.0, *)
private extension ElementNode {
    // The element as nesting too deep to evaluate leaves it: its props are dropped.
    var withoutProps: ElementNode {
        ElementNode(typeName: typeName, partial: partial, hasDynamicProps: false, statementId: statementId)
    }
}
