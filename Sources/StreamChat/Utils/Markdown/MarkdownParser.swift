/**
 *  Ink
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

import Foundation

///
/// A parser used to convert Markdown text into HTML.
///
/// You can use an instance of this type to either convert
/// a Markdown string into an HTML string, or into a `Markdown`
/// value, which also contains any metadata values found in
/// the parsed Markdown text.
///
/// To customize how this parser performs its work, attach
/// a `Modifier` using the `addModifier` method.
public struct MarkdownParser {
    private var modifiers: ModifierCollection

    /// Initialize an instance, optionally passing an array
    /// of modifiers used to customize the parsing process.
    public init(modifiers: [Modifier] = []) {
        self.modifiers = ModifierCollection(modifiers: modifiers)
    }

    /// Add a modifier to this parser, which can be used to
    /// customize the parsing process. See `Modifier` for more info.
    public mutating func addModifier(_ modifier: Modifier) {
        modifiers.insert(modifier)
    }

    /// Parse a Markdown string into a `Markdown` value, which contains
    /// both the HTML representation of the given string, and also any
    /// metadata values found within it.
    public func parse(_ markdown: String) -> String {
        var reader = Reader(string: markdown)
        var fragments = [ParsedFragment]()
        var urlsByName = [String: Substring]()

        while !reader.didReachEnd {
            reader.discardWhitespacesAndNewlines()
            guard !reader.didReachEnd else { break }

            do {
                guard reader.currentCharacter != "[" else {
                    let declaration = try URLDeclaration.readOrRewind(using: &reader)
                    urlsByName[declaration.name] = declaration.url
                    continue
                }

                let type = fragmentType(
                    for: reader.currentCharacter,
                    nextCharacter: reader.nextCharacter
                )

                #if swift(>=5.3) && swift(<5.4) && os(Linux)
                // inline function call to work around https://bugs.swift.org/browse/SR-13645
                let fragment: ParsedFragment = try {
                    let startIndex = reader.currentIndex
                    let fragment = try type.readOrRewind(using: &reader)
                    let rawString = reader.characters(in: startIndex..<reader.currentIndex)
                    return ParsedFragment(fragment: fragment, rawString: rawString)
                }()
                #else
                let fragment = try makeFragment(using: type.readOrRewind, reader: &reader)
                #endif
                fragments.append(fragment)
            } catch {
                let paragraph = makeFragment(using: Paragraph.read, reader: &reader)
                fragments.append(paragraph)
            }
        }

        let urls = NamedURLCollection(urlsByName: urlsByName)

        let html = fragments.reduce(into: "") { result, wrapper in
            let html = wrapper.fragment.html(
                usingURLs: urls,
                rawString: wrapper.rawString,
                applyingModifiers: modifiers
            )

            result.append(html)
        }

        return html
    }
}

private extension MarkdownParser {
    struct ParsedFragment {
        var fragment: Fragment
        var rawString: Substring
    }

    func makeFragment(
        using closure: (inout Reader) throws -> Fragment,
        reader: inout Reader
    ) rethrows -> ParsedFragment {
        let startIndex = reader.currentIndex
        let fragment = try closure(&reader)
        let rawString = reader.characters(in: startIndex..<reader.currentIndex)
        return ParsedFragment(fragment: fragment, rawString: rawString)
    }

    func fragmentType(
        for character: Character,
        nextCharacter: Character?
    ) -> Fragment.Type {
        switch character {
        case "#": return Heading.self
        case "!": return Image.self
        case "<": return HTML.self
        case ">": return Blockquote.self
        case "`": return CodeBlock.self
        case "-" where character == nextCharacter,
             "*" where character == nextCharacter:
            return HorizontalLine.self
        case "-", "*", "+", \.isNumber: return List.self
        case "|": return Table.self
        default: return Paragraph.self
        }
    }
}
