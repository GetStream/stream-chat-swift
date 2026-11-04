//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A block of Markdown content.
@available(iOS 17.0, macOS 14.0, *)
enum MarkdownBlock: Sendable, Hashable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case list(MarkdownList)
    case quote([MarkdownBlock])
    case code(language: String?, code: String)
    case table(MarkdownTable)
    case rule
}

@available(iOS 17.0, macOS 14.0, *)
struct MarkdownList: Sendable, Hashable {
    struct Item: Sendable, Hashable {
        var text: String
        /// `true`/`false` for task list items (`- [x]`), `nil` otherwise.
        var checked: Bool?
        var children: [MarkdownBlock]
    }

    var ordered: Bool
    var start: Int
    var items: [Item]
}

@available(iOS 17.0, macOS 14.0, *)
struct MarkdownTable: Sendable, Hashable {
    enum Alignment: Sendable, Hashable {
        case leading, center, trailing
    }

    var header: [String]
    var alignments: [Alignment]
    var rows: [[String]]
}

/// A small, streaming-tolerant Markdown block parser (CommonMark/GFM subset: headings, paragraphs,
/// nested lists, task lists, block quotes, fenced code, tables and rules). Inline formatting is
/// handled by `AttributedString(markdown:)` when rendering.
@available(iOS 17.0, macOS 14.0, *)
enum MarkdownParser {
    static func parse(_ text: String) -> [MarkdownBlock] {
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var index = 0
        return parseBlocks(lines, &index, indent: 0, depth: 0)
    }

    // Quotes and lists nest this deep at most; deeper markers read as text, so the model's
    // text can't recurse until the stack runs out.
    static let maxDepth = 32

    private static func leadingSpaces(_ line: String) -> Int {
        var count = 0
        for character in line {
            if character == " " { count += 1 } else if character == "\t" { count += 4 } else { break }
        }
        return count
    }

    // Drops `columns` of indentation, counting a tab as 4 like `leadingSpaces`, and never more
    // than the leading spaces and tabs.
    private static func dedent(_ line: String, by columns: Int) -> String {
        var remaining = columns
        var start = line.startIndex
        while remaining > 0, start < line.endIndex {
            switch line[start] {
            case " ": remaining -= 1
            case "\t": remaining -= 4
            default: return String(line[start...])
            }
            start = line.index(after: start)
        }
        return String(repeating: " ", count: max(0, -remaining)) + line[start...]
    }

    private static func isBlank(_ line: String) -> Bool {
        line.allSatisfy { $0 == " " || $0 == "\t" }
    }

    private static func headingMatch(_ line: String) -> (Int, String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        var level = 0
        for character in trimmed {
            if character == "#" { level += 1 } else { break }
        }
        guard (1...6).contains(level) else { return nil }
        let rest = trimmed.dropFirst(level)
        guard rest.isEmpty || rest.first == " " else { return nil }
        var text = rest.trimmingCharacters(in: .whitespaces)
        while text.hasSuffix("#") { text.removeLast() }
        return (level, text.trimmingCharacters(in: .whitespaces))
    }

    private static func isRule(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        guard compact.count >= 3, let first = compact.first, "-*_".contains(first) else { return false }
        return compact.allSatisfy { $0 == first }
    }

    private static func fence(_ line: String) -> (marker: String, info: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        for marker in ["```", "~~~"] where trimmed.hasPrefix(marker) {
            let info = trimmed.drop(while: { $0 == marker.first }).trimmingCharacters(in: .whitespaces)
            return (marker, info)
        }
        return nil
    }

    /// `(ordered, number, content, contentIndent)` for a list item line.
    private static func listItem(_ line: String) -> (ordered: Bool, number: Int, content: String, indent: Int)? {
        let indent = leadingSpaces(line)
        let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })
        if let first = trimmed.first, "-*+".contains(first) {
            let rest = trimmed.dropFirst()
            guard rest.isEmpty || rest.first == " " else { return nil }
            return (false, 0, String(rest.drop(while: { $0 == " " })), indent + 2)
        }
        let digits = trimmed.prefix(while: { $0.isNumber })
        guard !digits.isEmpty, digits.count <= 9 else { return nil }
        let afterDigits = trimmed.dropFirst(digits.count)
        guard let delimiter = afterDigits.first, delimiter == "." || delimiter == ")" else { return nil }
        let rest = afterDigits.dropFirst()
        guard rest.isEmpty || rest.first == " " else { return nil }
        return (true, Int(digits) ?? 1, String(rest.drop(while: { $0 == " " })), indent + digits.count + 2)
    }

    private static func tableCells(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") && !trimmed.hasSuffix("\\|") { trimmed.removeLast() }
        var cells: [String] = []
        var current = ""
        var escaped = false
        for character in trimmed {
            if escaped {
                current.append(character)
                escaped = false
            } else if character == "\\" {
                escaped = true
                current.append(character)
            } else if character == "|" {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }
        }
        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells.map { $0.replacingOccurrences(of: "\\|", with: "|") }
    }

    private static func tableAlignments(_ line: String) -> [MarkdownTable.Alignment]? {
        guard line.contains("-") else { return nil }
        let cells = tableCells(line)
        var alignments: [MarkdownTable.Alignment] = []
        for cell in cells {
            let compact = cell.replacingOccurrences(of: " ", with: "")
            guard !compact.isEmpty, compact.allSatisfy({ $0 == "-" || $0 == ":" }), compact.contains("-") else { return nil }
            switch (compact.hasPrefix(":"), compact.hasSuffix(":")) {
            case (true, true): alignments.append(.center)
            case (false, true): alignments.append(.trailing)
            default: alignments.append(.leading)
            }
        }
        return alignments
    }

    private static func parseBlocks(_ lines: [String], _ index: inout Int, indent: Int, depth: Int) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []

        func flushParagraph() {
            if !paragraph.isEmpty {
                blocks.append(.paragraph(paragraph.joined(separator: "\n")))
                paragraph.removeAll()
            }
        }

        while index < lines.count {
            let rawLine = lines[index]
            if !isBlank(rawLine) && leadingSpaces(rawLine) < indent && indent > 0 {
                break
            }
            let line = dedent(rawLine, by: indent)

            if isBlank(line) {
                flushParagraph()
                index += 1
                // A blank line ends a nested block unless the next line keeps the indentation.
                if indent > 0 {
                    var next = index
                    while next < lines.count && isBlank(lines[next]) { next += 1 }
                    if next >= lines.count || leadingSpaces(lines[next]) < indent { return blocks }
                }
                continue
            }

            if let (marker, info) = fence(line) {
                flushParagraph()
                index += 1
                var codeLines: [String] = []
                while index < lines.count {
                    let codeLine = dedent(lines[index], by: indent)
                    if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix(marker) {
                        index += 1
                        break
                    }
                    codeLines.append(codeLine)
                    index += 1
                }
                blocks.append(.code(language: info.isEmpty ? nil : info, code: codeLines.joined(separator: "\n")))
                continue
            }

            if let (level, text) = headingMatch(line) {
                flushParagraph()
                blocks.append(.heading(level: level, text: text))
                index += 1
                continue
            }

            if isRule(line) {
                flushParagraph()
                blocks.append(.rule)
                index += 1
                continue
            }

            if depth < maxDepth, line.trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                var end = index
                var quoted: [String] = []
                while end < lines.count {
                    let quoteLine = lines[end].trimmingCharacters(in: .whitespaces)
                    guard quoteLine.hasPrefix(">") else { break }
                    var content = String(quoteLine.dropFirst())
                    if content.hasPrefix(" ") { content.removeFirst() }
                    quoted.append(content)
                    end += 1
                }
                // A line that takes no quote lines reads as text below, so every pass moves on.
                if !quoted.isEmpty {
                    flushParagraph()
                    index = end
                    var quoteIndex = 0
                    blocks.append(.quote(parseBlocks(quoted, &quoteIndex, indent: 0, depth: depth + 1)))
                    continue
                }
            }

            if line.contains("|"), index + 1 < lines.count, let alignments = tableAlignments(lines[index + 1]) {
                flushParagraph()
                let header = tableCells(line)
                index += 2
                var rows: [[String]] = []
                while index < lines.count, !isBlank(lines[index]), lines[index].contains("|") {
                    rows.append(tableCells(lines[index]))
                    index += 1
                }
                let width = header.count
                blocks.append(.table(MarkdownTable(
                    header: header,
                    alignments: Array((alignments + Array(repeating: .leading, count: max(0, width - alignments.count))).prefix(width)),
                    rows: rows.map { row in Array((row + Array(repeating: "", count: max(0, width - row.count))).prefix(width)) }
                )))
                continue
            }

            if depth < maxDepth, let first = listItem(line) {
                flushParagraph()
                var items: [MarkdownList.Item] = []
                let ordered = first.ordered
                while index < lines.count {
                    if indent > 0 && leadingSpaces(lines[index]) < indent { break }
                    let current = dedent(lines[index], by: indent)
                    guard let item = listItem(current), item.ordered == ordered, leadingSpaces(current) < first.indent else { break }
                    index += 1
                    var text = item.content
                    var checked: Bool?
                    if text.hasPrefix("[ ] ") || text == "[ ]" {
                        checked = false
                        text = String(text.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    } else if text.lowercased().hasPrefix("[x] ") || text.lowercased() == "[x]" {
                        checked = true
                        text = String(text.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    }
                    // Lazy continuation lines belong to the item text.
                    while index < lines.count {
                        let next = lines[index]
                        if isBlank(next) || listItem(next) != nil || leadingSpaces(next) >= indent + item.indent { break }
                        let trimmedNext = next.trimmingCharacters(in: .whitespaces)
                        if headingMatch(trimmedNext) != nil || fence(trimmedNext) != nil || trimmedNext.hasPrefix(">") { break }
                        text += "\n" + trimmedNext
                        index += 1
                    }
                    let children = parseBlocks(lines, &index, indent: indent + item.indent, depth: depth + 1)
                    items.append(MarkdownList.Item(text: text, checked: checked, children: children))
                }
                blocks.append(.list(MarkdownList(ordered: ordered, start: first.number, items: items)))
                continue
            }

            paragraph.append(line.trimmingCharacters(in: .whitespaces))
            index += 1
        }
        flushParagraph()
        return blocks
    }
}
