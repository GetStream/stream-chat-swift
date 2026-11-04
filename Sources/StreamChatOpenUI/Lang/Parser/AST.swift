//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A named child of an object literal or a component's mapped props.
@available(iOS 17.0, macOS 14.0, *)
struct ASTEntry: Sendable, Hashable {
    var key: String
    var value: ASTNode

    init(_ key: String, _ value: ASTNode) {
        self.key = key
        self.value = value
    }
}

/// Whether a runtime reference points at a `Query` or a `Mutation` declaration.
@available(iOS 17.0, macOS 14.0, *)
enum RuntimeRefType: String, Sendable, Hashable {
    case query
    case mutation
}

/// Expression tree produced by the OpenUI Lang parser (mirrors `ASTNode` in `@openuidev/lang-core`).
///
/// Literal & structural nodes:
/// - ``comp(name:args:mappedProps:)`` — a component or builtin call: `Header("Hello")`, `@Count(rows)`
/// - ``str(_:)``, ``num(_:)``, ``bool(_:)``, ``null`` — literals
/// - ``arr(_:)``, ``obj(_:)`` — array and object literals
/// - ``ref(_:)`` — a reference to another statement
/// - ``placeholder(_:)`` — an unresolvable reference
///
/// Reactive & expression nodes (preserved for runtime evaluation):
/// - ``stateRef(_:)`` — `$variable`
/// - ``runtimeRef(_:refType:)`` — a reference to a `Query`/`Mutation` result
/// - ``binary(_:_:_:)``, ``unary(_:_:)``, ``ternary(_:_:_:)``
/// - ``member(_:_:)`` (`a.b`), ``index(_:_:)`` (`a[b]`), ``assign(_:_:)`` (`$a = expr`)
@available(iOS 17.0, macOS 14.0, *)
indirect enum ASTNode: Sendable, Hashable {
    /// A call: a component, built-in, library function or action step. `isFunction` marks an
    /// `@Name(...)` call whose name is not a built-in.
    case comp(name: String, args: [ASTNode], mappedProps: [ASTEntry]?, isFunction: Bool = false)
    case str(String)
    case num(Double)
    case bool(Bool)
    case null
    case arr([ASTNode])
    case obj([ASTEntry])
    case ref(String)
    case placeholder(String)
    case stateRef(String)
    case runtimeRef(String, refType: RuntimeRefType)
    case binary(String, ASTNode, ASTNode)
    case unary(String, ASTNode)
    case ternary(ASTNode, ASTNode, ASTNode)
    case member(ASTNode, String)
    case index(ASTNode, ASTNode)
    case assign(String, ASTNode)

    /// Convenience constructor for an unmapped call.
    static func call(_ name: String, _ args: [ASTNode]) -> ASTNode {
        .comp(name: name, args: args, mappedProps: nil)
    }

    /// The literal AST of a plain value: `{n: [1]}` → `Obj(n: Arr(Num 1))`.
    init(literal value: OpenUIValue) {
        switch value {
        case .string(let string): self = .str(string)
        case .number(let number): self = .num(number)
        case .bool(let bool): self = .bool(bool)
        case .array(let items): self = .arr(items.map(ASTNode.init(literal:)))
        case .object(let object): self = .obj(object.entries.map { ASTEntry($0.key, ASTNode(literal: $0.value)) })
        case .null, .element, .expression: self = .null
        }
    }

    /// The value of a literal AST, or `nil` when it holds a reference, call or expression.
    var literalValue: OpenUIValue? {
        switch self {
        case .str(let string): return .string(string)
        case .num(let number): return .number(number)
        case .bool(let bool): return .bool(bool)
        case .null: return .null
        case .arr(let elements):
            var items: [OpenUIValue] = []
            for element in elements {
                guard let item = element.literalValue else { return nil }
                items.append(item)
            }
            return .array(items)
        case .obj(let entries):
            var object = OpenUIObject()
            for entry in entries {
                guard let item = entry.value.literalValue else { return nil }
                object[entry.key] = item
            }
            return .object(object)
        default:
            return nil
        }
    }

    /// True for nodes that survive parser lowering and are resolved by the evaluator.
    var isRuntimeExpression: Bool {
        switch self {
        case .stateRef, .runtimeRef, .binary, .unary, .ternary, .member, .index, .assign:
            return true
        default:
            return false
        }
    }

    /// Visits this node and all of its descendants (pre-order).
    func walk(_ visit: (ASTNode) -> Void) {
        visit(self)
        switch self {
        case .comp(_, let args, let mappedProps, _):
            args.forEach { $0.walk(visit) }
            mappedProps?.forEach { $0.value.walk(visit) }
        case .arr(let elements):
            elements.forEach { $0.walk(visit) }
        case .obj(let entries):
            entries.forEach { $0.value.walk(visit) }
        case .binary(_, let left, let right):
            left.walk(visit)
            right.walk(visit)
        case .unary(_, let operand):
            operand.walk(visit)
        case .ternary(let condition, let then, let otherwise):
            condition.walk(visit)
            then.walk(visit)
            otherwise.walk(visit)
        case .member(let object, _):
            object.walk(visit)
        case .index(let object, let index):
            object.walk(visit)
            index.walk(visit)
        case .assign(_, let value):
            value.walk(visit)
        case .str, .num, .bool, .null, .ref, .placeholder, .stateRef, .runtimeRef:
            break
        }
    }

    /// Names of all `$variables` referenced by this expression, in first-seen order.
    var stateReferences: [String] {
        var seen = Set<String>()
        var result: [String] = []
        walk { node in
            if case .stateRef(let name) = node, seen.insert(name).inserted {
                result.append(name)
            }
        }
        return result
    }

    /// The JSON shape used by the reference implementation (`{ k: "Comp", name, args, ... }`).
    var jsonValue: OpenUIValue {
        switch self {
        case .comp(let name, let args, let mappedProps, let isFunction):
            var object: OpenUIObject = ["k": "Comp", "name": .string(name), "args": .array(args.map(\.jsonValue))]
            if isFunction { object["fn"] = true }
            if let mappedProps {
                object["mappedProps"] = .object(OpenUIObject(mappedProps.map { ($0.key, $0.value.jsonValue) }))
            }
            return .object(object)
        case .str(let value):
            return ["k": "Str", "v": .string(value)]
        case .num(let value):
            return ["k": "Num", "v": value.isFinite ? .number(value) : .null]
        case .bool(let value):
            return ["k": "Bool", "v": .bool(value)]
        case .null:
            return ["k": "Null"]
        case .arr(let elements):
            return ["k": "Arr", "els": .array(elements.map(\.jsonValue))]
        case .obj(let entries):
            return ["k": "Obj", "entries": .array(entries.map { .array([.string($0.key), $0.value.jsonValue]) })]
        case .ref(let name):
            return ["k": "Ref", "n": .string(name)]
        case .placeholder(let name):
            return ["k": "Ph", "n": .string(name)]
        case .stateRef(let name):
            return ["k": "StateRef", "n": .string(name)]
        case .runtimeRef(let name, let refType):
            return ["k": "RuntimeRef", "n": .string(name), "refType": .string(refType.rawValue)]
        case .binary(let op, let left, let right):
            return ["k": "BinOp", "op": .string(op), "left": left.jsonValue, "right": right.jsonValue]
        case .unary(let op, let operand):
            return ["k": "UnaryOp", "op": .string(op), "operand": operand.jsonValue]
        case .ternary(let condition, let then, let otherwise):
            return ["k": "Ternary", "cond": condition.jsonValue, "then": then.jsonValue, "else": otherwise.jsonValue]
        case .member(let object, let field):
            return ["k": "Member", "obj": object.jsonValue, "field": .string(field)]
        case .index(let object, let index):
            return ["k": "Index", "obj": object.jsonValue, "index": index.jsonValue]
        case .assign(let target, let value):
            return ["k": "Assign", "target": .string(target), "value": value.jsonValue]
        }
    }
}

/// Statement kinds, classified at parse time (mirrors `Statement` in `ast.ts`).
@available(iOS 17.0, macOS 14.0, *)
enum Statement: Sendable {
    case value(id: String, expr: ASTNode)
    case state(id: String, initial: ASTNode)
    case query(id: String, args: [ASTNode], expr: ASTNode, deps: [String]?)
    case mutation(id: String, args: [ASTNode], expr: ASTNode)

    var id: String {
        switch self {
        case .value(let id, _), .state(let id, _), .query(let id, _, _, _), .mutation(let id, _, _):
            return id
        }
    }

    /// The expression stored in the symbol table for this statement.
    var symbol: ASTNode {
        switch self {
        case .value(_, let expr), .query(_, _, let expr, _), .mutation(_, _, let expr):
            return expr
        case .state(_, let initial):
            return initial
        }
    }
}
