//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Pratt (top-down operator precedence) parser for OpenUI Lang expressions
/// (port of `parseExpression` in `expressions.ts`).
@available(iOS 17.0, macOS 14.0, *)
struct ExpressionParser {
    private static let precTernary = 1
    private static let precOr = 2
    private static let precAnd = 3
    private static let precEquality = 4
    private static let precComparison = 5
    private static let precAdditive = 6
    private static let precMultiplicative = 7
    private static let precUnary = 8
    private static let precMember = 9

    // How deep one statement's expressions nest, and how tall one subtree grows. The parser
    // recurses for each level of nesting, and walking or freeing the tree recurses for each level
    // of its height, which a chain like `1 + 1 + 1` raises without nesting. A statement past
    // either, which no real program is, reads as null instead of running out of stack.
    static let maxDepth = 256

    private struct Parsed {
        let node: ASTNode
        let height: Int

        init(_ node: ASTNode, height: Int = 1) {
            self.node = node
            self.height = height
        }

        init(_ node: ASTNode, children: [Parsed]) {
            self.init(node, height: 1 + (children.map(\.height).max() ?? 0))
        }
    }

    private let tokens: [Token]
    private var position = 0
    private var depth = 0

    private init(tokens: [Token]) {
        self.tokens = tokens
    }

    static func parse(_ tokens: [Token]) -> ASTNode {
        var parser = ExpressionParser(tokens: tokens)
        return parser.parseExpression(minPrecedence: 0).node
    }

    private var current: Token {
        position < tokens.count ? tokens[position] : .eof
    }

    private func peek(_ offset: Int) -> Token? {
        let index = position + offset
        return index < tokens.count ? tokens[index] : nil
    }

    @discardableResult
    private mutating func advance() -> Token {
        let token = current
        position += 1
        return token
    }

    private mutating func eat(_ kind: TokenKind) {
        if current.kind == kind { position += 1 }
    }

    private static func infixPrecedence(_ token: Token) -> Int {
        switch token.kind {
        case .question: return precTernary
        case .or: return precOr
        case .and: return precAnd
        case .eqEq, .notEq: return precEquality
        case .greater, .less, .greaterEq, .lessEq: return precComparison
        case .plus, .minus: return precAdditive
        case .star, .slash, .percent: return precMultiplicative
        case .dot, .lBrack: return precMember
        default: return 0
        }
    }

    private mutating func parseExpression(minPrecedence: Int) -> Parsed {
        depth += 1
        defer { depth -= 1 }
        guard depth <= Self.maxDepth else { return giveUp() }
        var left = parsePrefix()
        while Self.infixPrecedence(current) > minPrecedence {
            left = parseInfix(left)
            if left.height > Self.maxDepth { return giveUp() }
        }
        return left
    }

    private mutating func giveUp() -> Parsed {
        position = tokens.count
        return Parsed(.null)
    }

    private mutating func parsePrefix() -> Parsed {
        let token = current
        switch token.kind {
        case .str:
            advance()
            return Parsed(.str(token.text ?? ""))
        case .num:
            advance()
            return Parsed(.num(token.number ?? .nan))
        case .true:
            advance()
            return Parsed(.bool(true))
        case .false:
            advance()
            return Parsed(.bool(false))
        case .null:
            advance()
            return Parsed(.null)
        case .lBrack:
            return parseArray()
        case .lBrace:
            return parseObject()
        case .stateVar:
            let name = token.text ?? ""
            advance()
            if current.kind == .equals {
                advance()
                let value = parseExpression(minPrecedence: 0)
                return Parsed(.assign(name, value.node), children: [value])
            }
            return Parsed(.stateRef(name))
        case .type:
            let name = token.text ?? ""
            // Builtins (Count, Each, Set, Run, ...) require the @ prefix — only Action is exempt.
            if peek(1)?.kind == .lParen, !Builtins.isBuiltin(name) || name == "Action" {
                return parseCall()
            }
            advance()
            return Parsed(.ref(name))
        case .builtinCall:
            if peek(1)?.kind == .lParen {
                let call = parseCall()
                guard case .comp(let name, let args, let mappedProps, _) = call.node, !Builtins.isBuiltin(name) else { return call }
                return Parsed(.comp(name: name, args: args, mappedProps: mappedProps, isFunction: true), height: call.height)
            }
            advance()
            return Parsed(.ref(token.text ?? ""))
        case .ident:
            advance()
            return Parsed(.ref(token.text ?? ""))
        case .not:
            advance()
            let operand = parseExpression(minPrecedence: Self.precUnary)
            return Parsed(.unary("!", operand.node), children: [operand])
        case .minus:
            advance()
            let operand = parseExpression(minPrecedence: Self.precUnary)
            return Parsed(.unary("-", operand.node), children: [operand])
        case .lParen:
            advance()
            let inner = parseExpression(minPrecedence: 0)
            eat(.rParen)
            return inner
        default:
            // Unknown token — skip it and yield null.
            advance()
            return Parsed(.null)
        }
    }

    private mutating func parseInfix(_ left: Parsed) -> Parsed {
        let token = current
        switch token.kind {
        case .plus:
            return parseBinary("+", left, Self.precAdditive)
        case .minus:
            return parseBinary("-", left, Self.precAdditive)
        case .star:
            return parseBinary("*", left, Self.precMultiplicative)
        case .slash:
            return parseBinary("/", left, Self.precMultiplicative)
        case .percent:
            return parseBinary("%", left, Self.precMultiplicative)
        case .eqEq:
            return parseBinary("==", left, Self.precEquality)
        case .notEq:
            return parseBinary("!=", left, Self.precEquality)
        case .greater:
            return parseBinary(">", left, Self.precComparison)
        case .less:
            return parseBinary("<", left, Self.precComparison)
        case .greaterEq:
            return parseBinary(">=", left, Self.precComparison)
        case .lessEq:
            return parseBinary("<=", left, Self.precComparison)
        case .and:
            return parseBinary("&&", left, Self.precAnd)
        case .or:
            return parseBinary("||", left, Self.precOr)
        case .question:
            advance()
            let then = parseExpression(minPrecedence: 0)
            eat(.colon)
            let otherwise = parseExpression(minPrecedence: 0)
            return Parsed(.ternary(left.node, then.node, otherwise.node), children: [left, then, otherwise])
        case .dot:
            advance()
            let fieldToken = current
            let field: String
            switch fieldToken.kind {
            case .ident, .type, .str, .num:
                advance()
                field = fieldToken.stringValue
            case .stateVar:
                advance()
                field = String((fieldToken.text ?? "").dropFirst())
            default:
                advance()
                field = "?"
            }
            return Parsed(.member(left.node, field), children: [left])
        case .lBrack:
            advance()
            let index = parseExpression(minPrecedence: 0)
            eat(.rBrack)
            return Parsed(.index(left.node, index.node), children: [left, index])
        default:
            return left
        }
    }

    private mutating func parseBinary(_ op: String, _ left: Parsed, _ precedence: Int) -> Parsed {
        advance()
        let right = parseExpression(minPrecedence: precedence)
        return Parsed(.binary(op, left.node, right.node), children: [left, right])
    }

    /// `Name(arg1, arg2, ...)`
    private mutating func parseCall() -> Parsed {
        let name = current.text ?? ""
        advance()
        eat(.lParen)
        var args: [Parsed] = []
        while current.kind != .rParen, current.kind != .eof {
            args.append(parseExpression(minPrecedence: 0))
            if current.kind == .comma { advance() }
        }
        eat(.rParen)
        return Parsed(.comp(name: name, args: args.map(\.node), mappedProps: nil), children: args)
    }

    /// `[a, b, ...]`
    private mutating func parseArray() -> Parsed {
        advance()
        var elements: [Parsed] = []
        while current.kind != .rBrack, current.kind != .eof {
            elements.append(parseExpression(minPrecedence: 0))
            if current.kind == .comma { advance() }
        }
        eat(.rBrack)
        return Parsed(.arr(elements.map(\.node)), children: elements)
    }

    /// `{ key: value, ... }`
    private mutating func parseObject() -> Parsed {
        advance()
        var entries: [ASTEntry] = []
        var values: [Parsed] = []
        while current.kind != .rBrace, current.kind != .eof {
            let keyToken = current
            let key: String
            switch keyToken.kind {
            case .ident, .str, .type, .num:
                advance()
                key = keyToken.stringValue
            case .stateVar:
                advance()
                key = String((keyToken.text ?? "").dropFirst())
            default:
                advance()
                key = "?"
            }
            eat(.colon)
            let value = parseExpression(minPrecedence: 0)
            entries.append(ASTEntry(key, value.node))
            values.append(value)
            if current.kind == .comma { advance() }
        }
        eat(.rBrace)
        return Parsed(.obj(entries), children: values)
    }
}
