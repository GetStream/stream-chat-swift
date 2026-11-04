//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The OpenUI message protocol (port of `parseMessage` and `buildMessage` in `message.ts`):
/// marker lines around a stored response.
///
/// ```text
/// ]]>openui:content?library=chat
/// <openui-lang or text>
/// ]]>openui:context
/// [<json>]
/// ]]>openui:end
/// ```
///
/// A regenerated response writes a new content line after the cut-off one; the last content wins.
/// Messages in the older `<content>`/`<context>` XML envelope still read.
@available(iOS 17.0, macOS 14.0, *)
enum MessageEnvelope {
    static let prefix = "]]>openui:"
    static let contentMarker = prefix + "content"
    static let contextMarker = prefix + "context"
    static let endMarker = prefix + "end"

    /// The parts of a stored message.
    struct Parsed: Sendable, Equatable {
        /// The body of the last `content` section, or the whole text when there is none.
        var content: String
        /// The body of the `context` section: parsed JSON, else the raw text. `nil` when absent.
        var context: OpenUIValue?
        /// The string attributes of the winning `content` marker.
        var attributes: [String: String]
        /// Whether an `end` line follows the winning `content` section.
        var isEnded: Bool
    }

    /// Splits a stored message into its content, context, attributes and end flag. While
    /// `isStreaming`, a last line that may be a marker cut mid-stream is held back.
    static func parse(_ raw: String, isStreaming: Bool = false) -> Parsed {
        let parsed = parseMarkers(raw, isStreaming: isStreaming)
        if parsed.hasMarkers { return parsed.message }
        return parseLegacyXML(raw) ?? parsed.message
    }

    /// Writes a stored message with its marker lines. The context is written as is when it is a
    /// string, else as JSON, and left out when `nil`.
    static func build(
        content: String,
        context: OpenUIValue? = nil,
        attributes: KeyValuePairs<String, String> = [:],
        end: Bool = false
    ) -> String {
        let query = attributes.map { "\(encode($0.key))=\(encode($0.value))" }.joined(separator: "&")
        var message = contentMarker + (query.isEmpty ? "" : "?\(query)") + "\n" + content
        if let context, context != .null {
            message += "\n" + contextMarker + "\n" + (context.stringValue ?? OpenUIJSON.stringify(context))
        }
        return end ? message + "\n" + endMarker : message
    }

    /// Whether the text contains recognizable OpenUI Lang (a fenced block or a top-level `root =`).
    static func hasLangSyntax(_ content: String?) -> Bool {
        guard let content, !content.isEmpty else { return false }
        if content.contains("```openui-lang") { return true }
        return content.range(of: #"(^|\n)\s*root\s*="#, options: .regularExpression) != nil
    }

    // MARK: - Markers

    private struct Section {
        var kind: String?
        var attributes: [String: String] = [:]
        var lines: [String] = []
    }

    // A regenerated response writes its content line right after the cut-off text, with no
    // newline before it. Start it on its own line so the last content wins.
    private static let retry = regex(#"([^\n])(?=\]\]>openui:content(?:\?|\r?\n|\z))"#)
    // While streaming, hold back a mid-line `]]>openui:con` that may become a content line.
    private static let retryCut = regex(#"[^\n](\]\]>[a-z:]*)\z"#)
    private static let marker = regex(#"^\]\]>openui:([a-z]+)(?:\?(.*))?\z"#)

    private static func regex(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("Invalid pattern \(pattern): \(error)")
        }
    }

    private static func parseMarkers(_ raw: String, isStreaming: Bool) -> (message: Parsed, hasMarkers: Bool) {
        var text = retry.stringByReplacingMatches(in: raw, range: NSRange(raw.startIndex..., in: raw), withTemplate: "$1\n")
        if isStreaming,
           let cut = retryCut.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let tail = Range(cut.range(at: 1), in: text),
           contentMarker.hasPrefix(text[tail]) {
            let ns = text as NSString
            text = ns.substring(to: cut.range.location + 1)
        }
        // Split on the line feed code unit, as JavaScript does: Swift reads "\r\n" as one Character.
        var lines = text.components(separatedBy: "\n")
        let last = lines[lines.count - 1]
        let isHeld = isStreaming && !last.isEmpty && (last.hasPrefix(prefix) || prefix.hasPrefix(last))
        if isHeld { lines.removeLast() }

        var sections = [Section()]
        var hasMarkers = false
        // The newline (and its `\r`) before a marker is not part of the body.
        func close() {
            guard let index = sections[sections.count - 1].lines.indices.last else { return }
            sections[sections.count - 1].lines[index] = dropCarriageReturn(sections[sections.count - 1].lines[index])
        }
        var endAt = -1
        for (index, line) in lines.enumerated() {
            let candidate = dropCarriageReturn(line)
            guard let match = marker.firstMatch(in: candidate, range: NSRange(candidate.startIndex..., in: candidate)),
                  let kindRange = Range(match.range(at: 1), in: candidate) else {
                sections[sections.count - 1].lines.append(line)
                continue
            }
            hasMarkers = true
            close()
            let kind = String(candidate[kindRange])
            if kind == "end" {
                endAt = sections.count - 1
                if index == lines.count - 2 && lines[index + 1].isEmpty { break }
                continue
            }
            let query = Range(match.range(at: 2), in: candidate).map { String(candidate[$0]) } ?? ""
            sections.append(Section(kind: kind, attributes: readAttributes(query)))
        }
        if isHeld { close() }

        // Last content wins; text before the first marker is content only when there is none.
        let kinds = sections.map(\.kind)
        let winner = max(0, kinds.lastIndex(of: "content") ?? 0)
        var context: OpenUIValue?
        if let contextIndex = kinds.lastIndex(of: "context"), contextIndex > winner {
            let body = sections[contextIndex].lines.joined(separator: "\n")
            context = (try? OpenUIJSON.parse(body)) ?? .string(body)
        }
        let message = Parsed(
            content: sections[winner].lines.joined(separator: "\n"),
            context: context,
            attributes: sections[winner].attributes,
            // Like context, an `end` before the winning content belongs to an earlier attempt.
            isEnded: endAt >= winner
        )
        return (message, hasMarkers)
    }

    private static func dropCarriageReturn(_ line: String) -> String {
        line.hasSuffix("\r") ? String(line.utf16.dropLast()) ?? line : line
    }

    private static func readAttributes(_ query: String) -> [String: String] {
        var attributes: [String: String] = [:]
        for pair in query.components(separatedBy: "&") {
            let parts = pair.components(separatedBy: "=")
            let key = decode(parts[0])
            guard !key.isEmpty else { continue }
            attributes[key] = parts.count > 1 ? decode(parts.dropFirst().joined(separator: "=")) : ""
        }
        return attributes
    }

    // Same bytes as URLSearchParams: unreserved characters stay, a space is "+".
    private static let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.* ")

    private static func encode(_ value: String) -> String {
        (value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? value).replacingOccurrences(of: " ", with: "+")
    }

    private static func decode(_ value: String) -> String {
        let spaced = value.replacingOccurrences(of: "+", with: " ")
        return spaced.removingPercentEncoding ?? spaced
    }

    // MARK: - Legacy

    private static func parseLegacyXML(_ raw: String) -> Parsed? {
        guard raw.contains("<content") || raw.contains("<context>") else { return nil }
        var content = raw
        var context: OpenUIValue?
        if let match = raw.range(of: #"<context>([\s\S]*)</context>\s*$"#, options: .regularExpression) {
            let inner = raw[match].replacingOccurrences(of: #"^<context>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"</context>\s*$"#, with: "", options: .regularExpression)
            context = (try? OpenUIJSON.parse(inner)) ?? .string(inner)
            content = JS.trimEnd(String(raw[..<match.lowerBound]))
        }
        if let match = content.range(of: #"^<content[^>]*>([\s\S]*)</content>\s*$"#, options: .regularExpression) {
            content = content[match].replacingOccurrences(of: #"^<content[^>]*>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"</content>\s*$"#, with: "", options: .regularExpression)
        }
        return Parsed(content: content, context: context, attributes: [:], isEnded: false)
    }
}
