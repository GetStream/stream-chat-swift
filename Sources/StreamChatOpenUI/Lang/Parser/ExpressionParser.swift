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

    // How deep one statement's expressions nest. The parser recurses for each level, so a
    // statement nested deeper, which no real program is, reads as null instead of running out
    // of stack.
    static let maxDepth = 256

    private let tokens: [Token]
    private var position = 0
    private var depth = 0

    private init(tokens: [Token]) {
        self.tokens = tokens
    }

    static func parse(_ tokens: [Token]) -> ASTNode {
        var parser = ExpressionParser(tokens: tokens)
        return parser.parseExpression(minPrecedence: 0)
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

    private mutating func parseExpression(minPrecedence: Int) -> ASTNode {
        depth += 1
        defer { depth -= 1 }
        guard depth <= Self.maxDepth else {
            position = tokens.count
            return .null
        }
        var left = parsePrefix()
        while Self.infixPrecedence(current) > minPrecedence {
            left = parseInfix(left)
        }
        return left
    }

    private mutating func parsePrefix() -> ASTNode {
        let token = current
        switch token.kind {
        case .str:
            advance()
            return .str(token.text ?? "")
        case .num:
            advance()
            return .num(token.number ?? .nan)
        case .true:
            advance()
            return .bool(true)
        case .false:
            advance()
            return .bool(false)
        case .null:
            advance()
            return .null
        case .lBrack:
            return parseArray()
        case .lBrace:
            return parseObject()
        case .stateVar:
            let name = token.text ?? ""
            advance()
            if current.kind == .equals {
                advance()
                return .assign(name, parseExpression(minPrecedence: 0))
            }
            return .stateRef(name)
        case .type:
            let name = token.text ?? ""
            // Builtins (Count, Each, Set, Run, ...) require the @ prefix — only Action is exempt.
            if peek(1)?.kind == .lParen, !Builtins.isBuiltin(name) || name == "Action" {
                return parseCall()
            }
            advance()
            return .ref(name)
        case .builtinCall:
            if peek(1)?.kind == .lParen {
                let call = parseCall()
                guard case .comp(let name, let args, let mappedProps, _) = call, !Builtins.isBuiltin(name) else { return call }
                return .comp(name: name, args: args, mappedProps: mappedProps, isFunction: true)
            }
            advance()
            return .ref(token.text ?? "")
        case .ident:
            advance()
            return .ref(token.text ?? "")
        case .not:
            advance()
            return .unary("!", parseExpression(minPrecedence: Self.precUnary))
        case .minus:
            advance()
            return .unary("-", parseExpression(minPrecedence: Self.precUnary))
        case .lParen:
            advance()
            let inner = parseExpression(minPrecedence: 0)
            eat(.rParen)
            return inner
        default:
            // Unknown token — skip it and yield null.
            advance()
            return .null
        }
    }

    private mutating func parseInfix(_ left: ASTNode) -> ASTNode {
        let token = current
        switch token.kind {
        case .plus:
            advance(); return .binary("+", left, parseExpression(minPrecedence: Self.precAdditive))
        case .minus:
            advance(); return .binary("-", left, parseExpression(minPrecedence: Self.precAdditive))
        case .star:
            advance(); return .binary("*", left, parseExpression(minPrecedence: Self.precMultiplicative))
        case .slash:
            advance(); return .binary("/", left, parseExpression(minPrecedence: Self.precMultiplicative))
        case .percent:
            advance(); return .binary("%", left, parseExpression(minPrecedence: Self.precMultiplicative))
        case .eqEq:
            advance(); return .binary("==", left, parseExpression(minPrecedence: Self.precEquality))
        case .notEq:
            advance(); return .binary("!=", left, parseExpression(minPrecedence: Self.precEquality))
        case .greater:
            advance(); return .binary(">", left, parseExpression(minPrecedence: Self.precComparison))
        case .less:
            advance(); return .binary("<", left, parseExpression(minPrecedence: Self.precComparison))
        case .greaterEq:
            advance(); return .binary(">=", left, parseExpression(minPrecedence: Self.precComparison))
        case .lessEq:
            advance(); return .binary("<=", left, parseExpression(minPrecedence: Self.precComparison))
        case .and:
            advance(); return .binary("&&", left, parseExpression(minPrecedence: Self.precAnd))
        case .or:
            advance(); return .binary("||", left, parseExpression(minPrecedence: Self.precOr))
        case .question:
            advance()
            let then = parseExpression(minPrecedence: 0)
            eat(.colon)
            let otherwise = parseExpression(minPrecedence: 0)
            return .ternary(left, then, otherwise)
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
            return .member(left, field)
        case .lBrack:
            advance()
            let index = parseExpression(minPrecedence: 0)
            eat(.rBrack)
            return .index(left, index)
        default:
            return left
        }
    }

    /// `Name(arg1, arg2, ...)`
    private mutating func parseCall() -> ASTNode {
        let name = current.text ?? ""
        advance()
        eat(.lParen)
        var args: [ASTNode] = []
        while current.kind != .rParen, current.kind != .eof {
            args.append(parseExpression(minPrecedence: 0))
            if current.kind == .comma { advance() }
        }
        eat(.rParen)
        return .comp(name: name, args: args, mappedProps: nil)
    }

    /// `[a, b, ...]`
    private mutating func parseArray() -> ASTNode {
        advance()
        var elements: [ASTNode] = []
        while current.kind != .rBrack, current.kind != .eof {
            elements.append(parseExpression(minPrecedence: 0))
            if current.kind == .comma { advance() }
        }
        eat(.rBrack)
        return .arr(elements)
    }

    /// `{ key: value, ... }`
    private mutating func parseObject() -> ASTNode {
        advance()
        var entries: [ASTEntry] = []
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
            entries.append(ASTEntry(key, parseExpression(minPrecedence: 0)))
            if current.kind == .comma { advance() }
        }
        eat(.rBrace)
        return .obj(entries)
    }
}
