//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The OpenUI chat message envelope (port of `sentinelParser.ts`).
///
/// Chat messages carry OpenUI Lang content plus an optional JSON context section (persisted form
/// state, or the context of a clicked action) using inline sentinels:
///
/// ```text
/// ]]>openui:content
/// <openui-lang or text>
/// ]]>openui:context
/// [<json>]
/// ```
@available(iOS 17.0, macOS 14.0, *)
public enum MessageEnvelope {
    static let sentinel = "]]>openui:"
    public static let contentMarker = sentinel + "content"
    public static let contextMarker = sentinel + "context"
    public static let endMarker = sentinel + "end"

    /// The parts of an envelope.
    public struct Parsed: Sendable, Equatable {
        /// The content section (sentinels and partial streaming tails stripped).
        public var content: String
        /// The raw JSON context section, if present.
        public var context: String?
        /// The original content header line (e.g. with attributes), if present.
        public var contentHeader: String?
        /// Whether the terminal end marker was present.
        public var ended: Bool
    }

    public static func wrapContent(_ text: String) -> String {
        "\(contentMarker)\n\(text)"
    }

    public static func wrapContent(_ text: String, header: String?) -> String {
        if let header { return "\(header)\n\(text)" }
        return wrapContent(text)
    }

    public static func wrapContext(_ json: String) -> String {
        "\n\(contextMarker)\n\(json)"
    }

    /// Wraps content plus a JSON-encoded context array.
    public static func wrap(content: String, context: [OpenUIValue]) -> String {
        wrapContent(content) + wrapContext(OpenUIJSON.stringify(.array(context)))
    }

    /// Splits a message into its content and context sections. Messages without sentinels are
    /// returned unchanged as content.
    public static func parse(_ raw: String) -> Parsed {
        let (text, ended) = extractEndMarker(raw)
        var parts = splitSections(text)
        parts.content = stripStreamingTail(parts.content)
        parts.ended = ended
        return parts
    }

    /// Whether the text contains recognizable OpenUI Lang (a fenced block or a top-level `root =`).
    public static func hasLangSyntax(_ content: String?) -> Bool {
        guard let content, !content.isEmpty else { return false }
        if content.contains("```openui-lang") { return true }
        return content.range(of: #"(^|\n)\s*root\s*="#, options: .regularExpression) != nil
    }

    // MARK: - Internals

    private static func splitSections(_ raw: String) -> Parsed {
        let lastContent = raw.range(of: contentMarker, options: .backwards)
        let lastContext = raw.range(of: contextMarker, options: .backwards)

        switch (lastContent, lastContext) {
        case (nil, nil):
            return parseLegacyXML(raw)
        case (nil, let context?):
            return Parsed(
                content: stripSectionSeparator(String(raw[..<context.lowerBound])),
                context: String(raw[bodyStart(raw, context.lowerBound)...]),
                contentHeader: nil,
                ended: false
            )
        case (let content?, nil):
            return Parsed(
                content: String(raw[bodyStart(raw, content.lowerBound)...]),
                context: nil,
                contentHeader: header(raw, content.lowerBound),
                ended: false
            )
        case (let content?, let context?):
            if content.lowerBound > context.lowerBound {
                return Parsed(
                    content: String(raw[bodyStart(raw, content.lowerBound)...]),
                    context: nil,
                    contentHeader: header(raw, content.lowerBound),
                    ended: false
                )
            }
            let bodyStartIndex = bodyStart(raw, content.lowerBound)
            let body = bodyStartIndex <= context.lowerBound ? String(raw[bodyStartIndex..<context.lowerBound]) : ""
            return Parsed(
                content: stripSectionSeparator(body),
                context: String(raw[bodyStart(raw, context.lowerBound)...]),
                contentHeader: header(raw, content.lowerBound),
                ended: false
            )
        }
    }

    private static func extractEndMarker(_ raw: String) -> (String, Bool) {
        var text = raw
        var ended = false
        while let marker = text.range(of: endMarker) {
            ended = true
            let before = stripSectionSeparator(String(text[..<marker.lowerBound]))
            let after: String
            if let lineEnd = text[marker.lowerBound...].firstIndex(where: \.isLineFeed) {
                after = String(text[text.index(after: lineEnd)...])
            } else {
                after = ""
            }
            text = after.isEmpty ? before : before + "\n" + after
        }
        return (text, ended)
    }

    /// Trims a proper prefix of a marker at the very end of streamed content.
    private static func stripStreamingTail(_ content: String) -> String {
        var trim = 0
        for token in [contentMarker, contextMarker, endMarker] {
            let maxLength = min(token.count - 1, content.count)
            var k = maxLength
            while k > trim {
                if content.hasSuffix(String(token.prefix(k))) {
                    trim = k
                    break
                }
                k -= 1
            }
        }
        guard trim > 0 else { return content }
        return stripSectionSeparator(String(content.dropLast(trim)))
    }

    private static func header(_ raw: String, _ markerStart: String.Index) -> String {
        if let lineEnd = raw[markerStart...].firstIndex(where: \.isLineFeed) {
            return String(raw[markerStart..<lineEnd])
        }
        return String(raw[markerStart...])
    }

    private static func bodyStart(_ raw: String, _ markerStart: String.Index) -> String.Index {
        if let lineEnd = raw[markerStart...].firstIndex(where: \.isLineFeed) {
            return raw.index(after: lineEnd)
        }
        return raw.endIndex
    }

    private static func stripSectionSeparator(_ value: String) -> String {
        if value.last?.isLineFeed == true { return String(value.dropLast()) }
        return value
    }

    /// Legacy `<content>…</content><context>…</context>` envelope.
    private static func parseLegacyXML(_ raw: String) -> Parsed {
        var content = raw
        var context: String?
        if let match = raw.range(of: #"<context>([\s\S]*)</context>\s*$"#, options: .regularExpression) {
            let inner = raw[match].replacingOccurrences(of: #"^<context>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"</context>\s*$"#, with: "", options: .regularExpression)
            context = inner
            content = JS.trimEnd(String(raw[..<match.lowerBound]))
        }
        if let match = content.range(of: #"^<content[^>]*>([\s\S]*)</content>\s*$"#, options: .regularExpression) {
            let inner = content[match].replacingOccurrences(of: #"^<content[^>]*>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"</content>\s*$"#, with: "", options: .regularExpression)
            content = inner
        }
        return Parsed(content: content, context: context, contentHeader: nil, ended: false)
    }
}

@available(iOS 17.0, macOS 14.0, *)
private extension Character {
    // A line break the envelope reads: "\n", or "\r\n", which Swift reads as one Character.
    var isLineFeed: Bool { self == "\n" || self == "\r\n" }
}
