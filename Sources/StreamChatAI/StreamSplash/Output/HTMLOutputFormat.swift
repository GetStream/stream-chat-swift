/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

/// Output format to use to generate an HTML string with a semantic
/// representation of the highlighted code. Each token will be wrapped
/// in a `span` element with a CSS class matching the token's type.
/// Optionally, a `classPrefix` can be set to prefix each CSS class with
/// a given string.
struct HTMLOutputFormat: OutputFormat {
    var classPrefix: String

    init(classPrefix: String = "") {
        self.classPrefix = classPrefix
    }

    func makeBuilder() -> Builder {
        return Builder(classPrefix: classPrefix)
    }
}

extension HTMLOutputFormat {
    struct Builder: OutputBuilder {
        private let classPrefix: String
        private var html = ""
        private var pendingToken: (string: String, type: TokenType)?
        private var pendingWhitespace: String?

        fileprivate init(classPrefix: String) {
            self.classPrefix = classPrefix
        }

        mutating func addToken(_ token: String, ofType type: TokenType) {
            if var pending = pendingToken {
                guard pending.type != type else {
                    pendingWhitespace.map { pending.string += $0 }
                    pendingWhitespace = nil
                    pending.string += token
                    pendingToken = pending
                    return
                }
            }

            appendPending()
            pendingToken = (token, type)
        }

        mutating func addPlainText(_ text: String) {
            appendPending()
            html.append(text.escapingHTMLEntities())
        }

        mutating func addWhitespace(_ whitespace: String) {
            if pendingToken != nil {
                pendingWhitespace = (pendingWhitespace ?? "") + whitespace
            } else {
                html.append(whitespace)
            }
        }

        mutating func build() -> String {
            appendPending()
            return html
        }

        private mutating func appendPending() {
            if let pending = pendingToken {
                html.append("""
                <span class="\(classPrefix)\(pending.type.string)">\(pending.string.escapingHTMLEntities())</span>
                """)

                pendingToken = nil
            }

            if let whitespace = pendingWhitespace {
                html.append(whitespace)
                pendingWhitespace = nil
            }
        }
    }
}
