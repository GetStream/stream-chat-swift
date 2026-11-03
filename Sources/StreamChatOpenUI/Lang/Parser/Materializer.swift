//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Schema-aware, single-pass lowering of parsed statements into element trees
/// (port of `materialize.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum Materializer {
    // How deep the materialized tree nests, references included. Materializing recurses for
    // each level, so a chain of references deeper than any real program reads as null instead
    // of running out of stack.
    static let maxDepth = 256
    // How many nodes one pass materializes, counting a reference's nodes again each place it is
    // used. Declarations that each use the previous one many times multiply that, so past the
    // budget nodes materialize to null.
    static let maxNodes = 100_000

    /// Whether a prop value contains anything that needs runtime evaluation.
    static func containsDynamicValue(_ value: OpenUIValue) -> Bool {
        switch value {
        case .expression:
            return true
        case .array(let items):
            return items.contains(where: containsDynamicValue)
        case .element(let element):
            return element.props.values.contains(where: containsDynamicValue)
        case .object(let object):
            // A `{steps: [...]}` literal is evaluated too, so data can't pose as custom action steps.
            if case .array? = object["steps"] { return true }
            return object.values.contains(where: containsDynamicValue)
        case .null, .bool, .number, .string:
            return false
        }
    }

    // MARK: - Calls

    static func callDefs(_ context: MaterializeContext) -> [String: CallDef] {
        context.catalog?.callDefs ?? Builtins.calls
    }

    /// Calls the runtime evaluates, which stay AST: functions, steps and reserved calls.
    static func isRuntimeCall(_ name: String, _ context: MaterializeContext) -> Bool {
        callDefs(context)[name] != nil || Builtins.isReservedCall(name)
    }

    /// `[Num 1, Ref x]` with params `[a, b]` → `a: Num 1, b: Ref x`; extra args are dropped.
    static func nameArgs(_ args: [ASTNode], _ params: [ParamDef]) -> [ASTEntry] {
        zip(params, args).map { ASTEntry($0.name, $1) }
    }

    /// Maps a library call's args to its params and checks the literal ones like props. Returns
    /// `nil` when the call is invalid: it then evaluates to null, or is a no-op for an action.
    static func mapCallArgs(_ name: String, _ args: [ASTNode], _ def: CallDef, _ context: MaterializeContext) -> [ASTEntry]? {
        let params = def.params
        if args.count > params.count {
            SchemaValidation.push(context, component: name, path: "", issue: .excessArgs(declared: params.count, got: args.count))
        }
        var mapped = nameArgs(args, params)
        var invalid = false
        let errorsBefore = context.errors.count
        for param in params {
            let index = mapped.firstIndex { $0.key == param.name }
            var literal: OpenUIValue?
            if let index {
                guard let value = mapped[index].value.literalValue else { continue }
                literal = value
            }
            guard let value = literal, value != .null else {
                if !param.required || param.defaultValue != nil { continue }
                let signature = SchemaValidation.paramsSignature(component: name, params: params)
                SchemaValidation.push(
                    context,
                    component: name,
                    path: "/\(param.name)",
                    issue: index == nil ? .missingRequired(signature: signature) : .nullRequired(signature: signature)
                )
                invalid = true
                continue
            }
            guard let schema = param.schema, let index else { continue }
            var next = value
            if SchemaValidation.validate(&next, schema: schema, component: name, path: "/\(param.name)", context: context) {
                if let defaultValue = param.defaultValue {
                    next = defaultValue
                } else if param.required {
                    invalid = true
                    continue
                } else {
                    mapped.remove(at: index)
                    continue
                }
            }
            if next != value {
                mapped[index].value = ASTNode(literal: next)
            }
        }
        // An action never runs with a value the model didn't write.
        if def.kind == .action && context.errors.count > errorsBefore { invalid = true }
        return invalid ? nil : mapped
    }

    /// `@Percent(3, total)` → `mappedProps` `part: Num 3, total: <total AST>`. An invalid library
    /// function is null, and an invalid action step an empty plan.
    private static func materializeCall(
        _ name: String,
        _ args: [ASTNode],
        _ existingMappedProps: [ASTEntry]?,
        _ isFunction: Bool,
        _ context: MaterializeContext,
        materializeArg: (ASTNode) -> ASTNode
    ) -> ASTNode {
        let recursed = args.map(materializeArg)
        guard let def = callDefs(context)[name], !def.isLazy else {
            return .comp(name: name, args: recursed, mappedProps: existingMappedProps, isFunction: isFunction)
        }
        let mapped = def.isBuiltin ? nameArgs(recursed, def.params) : mapCallArgs(name, recursed, def, context)
        if let mapped {
            return .comp(name: name, args: recursed, mappedProps: mapped, isFunction: isFunction)
        }
        return def.kind == .action ? .call("Action", [.arr([])]) : .null
    }

    /// Names the args of the calls inside a `Query` or `Mutation`'s args, such as
    /// `Query("s", {n: @Count(rows)})`. Literal library args are checked like props; an invalid
    /// call keeps its raw names and is null at runtime.
    static func nameRawCallArgs(_ args: [ASTNode], _ context: MaterializeContext, statementId: String) -> [ASTNode] {
        let previousStatementId = context.currentStatementId
        context.currentStatementId = statementId
        defer { context.currentStatementId = previousStatementId }
        return args.map { nameCallArgs($0, context) }
    }

    private static func nameCallArgs(_ node: ASTNode, _ context: MaterializeContext) -> ASTNode {
        switch node {
        case .comp(let name, let args, let mappedProps, let isFunction):
            guard let def = callDefs(context)[name], !def.isLazy else {
                return .comp(
                    name: name,
                    args: args.map { nameCallArgs($0, context) },
                    mappedProps: mappedProps?.map { ASTEntry($0.key, nameCallArgs($0.value, context)) },
                    isFunction: isFunction
                )
            }
            let checked = def.isBuiltin ? nil : mapCallArgs(name, args, def, context)
            let named = (checked ?? nameArgs(args, def.params)).map { ASTEntry($0.key, nameCallArgs($0.value, context)) }
            return .comp(name: name, args: args.map { nameCallArgs($0, context) }, mappedProps: named, isFunction: isFunction)
        case .arr(let elements):
            return .arr(elements.map { nameCallArgs($0, context) })
        case .obj(let entries):
            return .obj(entries.map { ASTEntry($0.key, nameCallArgs($0.value, context)) })
        case .binary(let op, let left, let right):
            return .binary(op, nameCallArgs(left, context), nameCallArgs(right, context))
        case .unary(let op, let operand):
            return .unary(op, nameCallArgs(operand, context))
        case .ternary(let condition, let then, let otherwise):
            return .ternary(nameCallArgs(condition, context), nameCallArgs(then, context), nameCallArgs(otherwise, context))
        case .member(let object, let field):
            return .member(nameCallArgs(object, context), field)
        case .index(let object, let index):
            return .index(nameCallArgs(object, context), nameCallArgs(index, context))
        case .assign(let target, let value):
            return .assign(target, nameCallArgs(value, context))
        case .str, .num, .bool, .null, .ref, .placeholder, .stateRef, .runtimeRef:
            return node
        }
    }

    private enum RefMode {
        case value
        case expression
    }

    enum RefResult: Sendable {
        case value(OpenUIValue)
        case expression(ASTNode)
    }

    /// Resolves a reference: inlines it from the symbol table, detects cycles, and emits runtime
    /// references for `Query`/`Mutation` declarations.
    private static func resolveRef(_ name: String, _ context: MaterializeContext, mode: RefMode) -> RefResult {
        let isCycle = context.visited.contains(name)
        if isCycle { context.cycles += 1 }
        guard !isCycle, let target = context.lookUp(name) else {
            context.unresolved.append(name)
            return mode == .expression ? .expression(.placeholder(name)) : .value(.null)
        }
        context.markReached(name)

        if case .comp(let callee, _, _, _) = target, Builtins.isReservedCall(callee) {
            let node = ASTNode.runtimeRef(name, refType: callee == Builtins.mutation ? .mutation : .query)
            return mode == .expression ? .expression(node) : .value(.expression(node))
        }

        if let reused = context.reuse(name, expression: mode == .expression) {
            return reused
        }
        let start = context.startMaterializing()
        context.visited.insert(name)
        let previousStatementId = context.currentStatementId
        context.currentStatementId = name

        let result: RefResult
        switch mode {
        case .value:
            var value = materializeValue(target, context)
            if case .element(var element) = value {
                element.statementId = name
                value = .element(element)
            }
            result = .value(value)
        case .expression:
            result = .expression(materializeExpression(target, context))
        }

        context.currentStatementId = previousStatementId
        context.visited.remove(name)
        context.finishMaterializing(start, name: name, expression: mode == .expression, result: result)
        return result
    }

    /// For lazy builtins like `@Each(array, varName, template)`, scopes the loop variable while
    /// materializing so template references resolve at runtime. Returns `nil` otherwise.
    private static func materializeLazyBuiltin(_ name: String, _ args: [ASTNode], _ context: MaterializeContext, scopedRefs: Set<String>) -> ASTNode? {
        guard let def = callDefs(context)[name], def.kind == .function, def.isLazy, args.count >= 3 else { return nil }
        let variableName: String
        switch args[1] {
        case .ref(let ref): variableName = ref
        case .str(let string): variableName = string
        default: return nil
        }
        guard !variableName.isEmpty else { return nil }

        var nextScopedRefs = scopedRefs
        nextScopedRefs.insert(variableName)
        let recursed = args.enumerated().map { index, arg in
            index == 1 ? arg : materializeExpression(arg, context, scopedRefs: nextScopedRefs)
        }
        return .comp(name: name, args: recursed, mappedProps: nil)
    }

    /// Normalizes an AST for runtime evaluation: resolves refs and maps catalog component args to props.
    static func materializeExpression(_ node: ASTNode, _ context: MaterializeContext, scopedRefs: Set<String> = []) -> ASTNode {
        context.depth += 1
        defer { context.depth -= 1 }
        guard context.spendNode() else { return .null }
        switch node {
        case .ref(let name):
            if scopedRefs.contains(name) { return node }
            switch resolveRef(name, context, mode: .expression) {
            case .expression(let resolved): return resolved
            case .value(let value): return value.expressionValue ?? .null
            }

        case .placeholder:
            return node

        case .comp(let name, let args, let existingMappedProps, let isFunction):
            if isFunction && !isRuntimeCall(name, context) {
                SchemaValidation.push(context, component: name, path: "", issue: .unknownFunction)
                return .null
            }
            if let lazy = materializeLazyBuiltin(name, args, context, scopedRefs: scopedRefs) {
                return lazy
            }
            if isRuntimeCall(name, context) {
                return materializeCall(name, args, existingMappedProps, isFunction, context) {
                    materializeExpression($0, context, scopedRefs: scopedRefs)
                }
            }
            let recursed = args.map { materializeExpression($0, context, scopedRefs: scopedRefs) }
            if let params = context.catalog?[name] {
                var mappedProps: [ASTEntry] = []
                for (index, param) in params.enumerated() where index < recursed.count {
                    mappedProps.append(ASTEntry(param.name, recursed[index]))
                }
                return .comp(name: name, args: recursed, mappedProps: mappedProps)
            }
            SchemaValidation.push(context, component: name, path: "", issue: .unknownComponent(available: context.catalog?.componentNames))
            return .comp(name: name, args: recursed, mappedProps: existingMappedProps)

        case .arr(let elements):
            return .arr(elements.map { materializeExpression($0, context, scopedRefs: scopedRefs) })

        case .obj(let entries):
            return .obj(entries.map { ASTEntry($0.key, materializeExpression($0.value, context, scopedRefs: scopedRefs)) })

        case .binary(let op, let left, let right):
            return .binary(op, materializeExpression(left, context, scopedRefs: scopedRefs), materializeExpression(right, context, scopedRefs: scopedRefs))

        case .unary(let op, let operand):
            return .unary(op, materializeExpression(operand, context, scopedRefs: scopedRefs))

        case .ternary(let condition, let then, let otherwise):
            return .ternary(
                materializeExpression(condition, context, scopedRefs: scopedRefs),
                materializeExpression(then, context, scopedRefs: scopedRefs),
                materializeExpression(otherwise, context, scopedRefs: scopedRefs)
            )

        case .member(let object, let field):
            return .member(materializeExpression(object, context, scopedRefs: scopedRefs), field)

        case .index(let object, let index):
            return .index(materializeExpression(object, context, scopedRefs: scopedRefs), materializeExpression(index, context, scopedRefs: scopedRefs))

        case .assign(let target, let value):
            return .assign(target, materializeExpression(value, context, scopedRefs: scopedRefs))

        case .str, .num, .bool, .null, .stateRef, .runtimeRef:
            return node
        }
    }

    /// Resolves refs, maps positional args to named props, validates them against the schema,
    /// applies defaults, and lowers literals to plain values. Runtime expressions stay as AST.
    static func materializeValue(_ node: ASTNode, _ context: MaterializeContext) -> OpenUIValue {
        context.depth += 1
        defer { context.depth -= 1 }
        guard context.spendNode() else { return .null }
        switch node {
        case .ref(let name):
            switch resolveRef(name, context, mode: .value) {
            case .value(let value): return value
            case .expression(let expression): return .expression(expression)
            }

        case .str(let value):
            return .string(value)
        case .num(let value):
            return .number(value)
        case .bool(let value):
            return .bool(value)
        case .null, .placeholder:
            return .null

        case .arr(let elements):
            var items: [OpenUIValue] = []
            for element in elements {
                if case .placeholder = element { continue }
                let value = materializeValue(element, context)
                // Drop nulls produced by unresolved refs, incomplete or unknown components.
                if value == .null {
                    switch element {
                    case .comp, .ref: continue
                    default: break
                    }
                }
                items.append(value)
            }
            return .array(items)

        case .obj(let entries):
            var object = OpenUIObject()
            for entry in entries {
                object[entry.key] = materializeValue(entry.value, context)
            }
            return .object(object)

        case .comp(let name, let args, let mappedProps, let isFunction):
            if isFunction && !isRuntimeCall(name, context) {
                SchemaValidation.push(context, component: name, path: "", issue: .unknownFunction)
                return .null
            }
            if Builtins.isReservedCall(name) {
                SchemaValidation.push(context, component: name, path: "", issue: .inlineReserved)
                return .null
            }
            if isRuntimeCall(name, context) {
                if let lazy = materializeLazyBuiltin(name, args, context, scopedRefs: []) {
                    return .expression(lazy)
                }
                return .expression(materializeCall(name, args, mappedProps, isFunction, context) { materializeExpression($0, context) })
            }
            return materializeComponent(name, args, context)

        case .stateRef, .runtimeRef, .binary, .unary, .ternary, .member, .index, .assign:
            return .expression(materializeExpression(node, context))
        }
    }

    private static func materializeComponent(_ name: String, _ args: [ASTNode], _ context: MaterializeContext) -> OpenUIValue {
        guard let params = context.catalog?[name] else {
            SchemaValidation.push(context, component: name, path: "", issue: .unknownComponent(available: context.catalog?.componentNames))
            return .null
        }

        var props = OpenUIObject()
        // Set when a REQUIRED prop holds invalid data with no default to fall back on.
        var dropComponent = false
        for (index, param) in params.enumerated() where index < args.count {
            var value = materializeValue(args[index], context)
            var invalid = false
            if let schema = param.schema {
                invalid = SchemaValidation.validate(&value, schema: schema, component: name, path: "/\(param.name)", context: context)
            }
            props[param.name] = value
            if invalid, SchemaValidation.resolveInvalidValue(&props, key: param.name, required: param.required, defaultValue: param.defaultValue) {
                dropComponent = true
            }
        }

        if args.count > params.count {
            SchemaValidation.push(context, component: name, path: "", issue: .excessArgs(declared: params.count, got: args.count))
        }

        let missingRequired = params.filter { param in
            param.required && (props[param.name] == nil || props[param.name] == .null)
        }
        if !missingRequired.isEmpty {
            var stillInvalid: [ParamDef] = []
            for param in missingRequired {
                if let defaultValue = param.defaultValue {
                    props[param.name] = defaultValue
                } else {
                    stillInvalid.append(param)
                }
            }
            if !stillInvalid.isEmpty {
                let signature = SchemaValidation.paramsSignature(component: name, params: params)
                for param in stillInvalid {
                    let issue: ValidationIssue = props.contains(param.name)
                        ? .nullRequired(signature: signature)
                        : .missingRequired(signature: signature)
                    SchemaValidation.push(context, component: name, path: "/\(param.name)", issue: issue)
                }
                return .null
            }
        }

        if dropComponent { return .null }

        let hasDynamicProps = props.values.contains(where: containsDynamicValue)
        return .element(ElementNode(typeName: name, props: props, partial: context.partial, hasDynamicProps: hasDynamicProps))
    }
}
