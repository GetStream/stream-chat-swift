//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A JSON Pointer (RFC 6901) style path into a surface data model.
///
/// Paths starting with `/` are absolute and always resolve from the root of the
/// data model. Paths without a leading slash are relative and resolve against
/// the current evaluation scope, which is how A2UI list templates address the
/// item they were instantiated for.
@available(iOS 15.0, macOS 12.0, *)
struct DataPath: Hashable, CustomStringConvertible, Sendable {
    /// The unescaped path segments, in order.
    let segments: [String]

    /// Whether the path resolves from the data model root.
    let isAbsolute: Bool

    /// The path pointing at the whole data model.
    static let root = DataPath(segments: [], isAbsolute: true)

    private static let separator: Character = "/"

    /// Parses a JSON Pointer string into a path.
    /// A leading `/` marks the path as absolute; `~0` and `~1` escapes are decoded.
    init(_ path: String) {
        let isAbsolute = path.hasPrefix(String(Self.separator))
        let segments = path
            .split(separator: Self.separator, omittingEmptySubsequences: true)
            .map { Self.unescape(String($0)) }
        self.segments = segments
        self.isAbsolute = isAbsolute
    }

    /// Creates a path from already-parsed segments.
    /// Use this when composing paths programmatically.
    init(segments: [String], isAbsolute: Bool) {
        self.segments = segments
        self.isAbsolute = isAbsolute
    }

    /// The last segment of the path, or an empty string for the root.
    var basename: String {
        segments.last ?? ""
    }

    /// The path with its last segment removed.
    /// The root path is returned unchanged.
    var dirname: DataPath {
        guard !segments.isEmpty else { return self }
        return DataPath(segments: Array(segments.dropLast()), isAbsolute: isAbsolute)
    }

    /// Whether this path addresses the whole data model.
    var isRoot: Bool {
        isAbsolute && segments.isEmpty
    }

    /// Whether a path's escapes are valid JSON Pointer escapes: every `~` is followed by `0` or `1`.
    static func isValidSyntax(_ path: String) -> Bool {
        var characters = path.makeIterator()
        while let character = characters.next() {
            if character == "~" {
                guard let escaped = characters.next(), escaped == "0" || escaped == "1" else { return false }
            }
        }
        return true
    }

    /// Appends another path to this one.
    /// Absolute paths replace this path instead of extending it.
    func appending(_ other: DataPath) -> DataPath {
        if other.isAbsolute { return other }
        // `.` is the current scope, so `.` and `./name` resolve inside it.
        return DataPath(segments: segments + other.segments.filter { $0 != "." }, isAbsolute: isAbsolute)
    }

    /// Appends a single segment to this path.
    /// Use this when descending into list indices or object keys.
    func appending(segment: String) -> DataPath {
        DataPath(segments: segments + [segment], isAbsolute: isAbsolute)
    }

    /// Whether this path is equal to, or nested inside, another path.
    /// Used to decide whether a data model change affects a subscription.
    func isDescendant(of other: DataPath) -> Bool {
        guard other.segments.count <= segments.count else { return false }
        for (index, segment) in other.segments.enumerated() where segments[index] != segment {
            return false
        }
        return true
    }

    /// The JSON Pointer string representation of the path.
    var description: String {
        let path = segments.map { Self.escape($0) }.joined(separator: String(Self.separator))
        return isAbsolute ? "\(Self.separator)\(path)" : path
    }

    private static func unescape(_ segment: String) -> String {
        segment
            .replacingOccurrences(of: "~1", with: "/")
            .replacingOccurrences(of: "~0", with: "~")
    }

    private static func escape(_ segment: String) -> String {
        segment
            .replacingOccurrences(of: "~", with: "~0")
            .replacingOccurrences(of: "/", with: "~1")
    }
}
