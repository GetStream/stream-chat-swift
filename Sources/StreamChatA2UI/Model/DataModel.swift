//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The mutable state backing a single A2UI surface.
///
/// The data model is a plain JSON object addressed with ``DataPath`` pointers.
/// Agents replace or patch it with `updateDataModel` messages, and input
/// components write to it directly as the user interacts with them.
///
/// Instances are not thread-safe. The renderer always mutates them from the
/// main actor, which is also where SwiftUI reads them.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class DataModel {
    /// A change to the data model, reported to observers.
    struct Change {
        /// The absolute path that was written.
        let path: DataPath

        /// The value written at `path`, or `nil` when the value was removed.
        let value: (any Sendable)?
    }

    private var storage: JsonMap
    private var observers: [UUID: (Change) -> Void] = [:]

    /// Creates a data model with an optional initial value.
    /// Pass the `dataModel` payload of a `createSurface` message here.
    init(_ initialValue: JsonMap = [:]) {
        self.storage = initialValue
    }

    /// The current contents of the data model.
    /// Use this when synchronizing state back to the agent.
    var snapshot: JsonMap {
        storage
    }

    /// Registers an observer that is notified after every write.
    /// Call the returned closure to stop observing.
    @discardableResult
    func observe(_ observer: @escaping (Change) -> Void) -> () -> Void {
        let token = UUID()
        observers[token] = observer
        return { [weak self] in
            self?.observers.removeValue(forKey: token)
        }
    }

    /// Reads the value at an absolute path.
    /// Returns `nil` when the path does not exist.
    func value(at path: DataPath) -> (any Sendable)? {
        Json.normalized(Self.read(storage, segments: path.segments))
    }

    /// Reads and coerces the value at an absolute path.
    /// Coercion follows the A2UI type conversion rules.
    func string(at path: DataPath) -> String? { Json.string(value(at: path)) }

    /// Writes a value at an absolute path, creating intermediate containers.
    ///
    /// Passing `nil` (or JSON `null`) removes the entry at `path`, matching the
    /// upsert semantics defined by the specification. Writing to the root path
    /// replaces the whole data model. A write the data model cannot apply is
    /// logged and ignored; use ``set(_:at:)`` to handle the failure.
    func update(at path: DataPath, value: (any Sendable)?) {
        do {
            try set(value, at: path)
        } catch {
            a2uiLogger.warning("Ignoring a data model write to '\(path)': \(A2UIErrorFormatter.describe(error))")
        }
    }

    /// Writes a value at an absolute path, creating intermediate containers.
    ///
    /// Passing `nil` (or JSON `null`) removes the entry at `path`; removing an
    /// array element leaves `null` in its place so later indices keep their
    /// meaning. Writing to the root path replaces the whole data model.
    ///
    /// - Throws: ``DataModelError`` when the path descends through a value that
    ///   is not a container, or uses an invalid array index. The data model is
    ///   left unchanged.
    func set(_ value: (any Sendable)?, at path: DataPath) throws {
        let newValue = Json.normalized(value)

        guard !path.segments.isEmpty else {
            if let newValue, Json.map(newValue) == nil {
                throw DataModelError.invalidRoot
            }
            storage = Json.map(newValue) ?? [:]
            notify(Change(path: .root, value: storage))
            return
        }

        guard path.segments.count <= A2UIProtocol.maxNestingDepth else {
            throw DataModelError.pathTooDeep(path)
        }
        if newValue == nil, Self.read(storage, segments: path.segments) == nil {
            return
        }
        var padding = Self.maxArrayIndex
        let updated = try Self.writing(newValue, into: storage, segments: path.segments[...], path: path, padding: &padding)
        storage = updated as? JsonMap ?? storage
        notify(Change(path: path, value: newValue))
    }

    /// Replaces the entire data model.
    /// Equivalent to writing to the root path.
    func replaceAll(with value: JsonMap) {
        update(at: .root, value: value)
    }

    private func notify(_ change: Change) {
        for observer in observers.values {
            observer(change)
        }
    }

    // MARK: - Traversal

    private static func read(_ root: (any Sendable)?, segments: [String]) -> (any Sendable)? {
        var current = root
        for segment in segments {
            if let map = current as? JsonMap {
                current = map[segment]
            } else if let list = current as? JsonArray, let index = arrayIndex(segment), index < list.count {
                current = list[index]
            } else {
                return nil
            }
        }
        return current
    }

    // `padding` is how many nulls the write may still add to fill gaps in arrays, across all of
    // its levels, so one write can't allocate an array of arrays of nulls.
    private static func writing(
        _ value: (any Sendable)?,
        into current: (any Sendable)?,
        segments: ArraySlice<String>,
        path: DataPath,
        padding: inout Int
    ) throws -> any Sendable {
        guard let segment = segments.first else { return value ?? NSNull() }
        let remaining = segments.dropFirst()

        if var map = current as? JsonMap {
            if remaining.isEmpty, value == nil {
                map.removeValue(forKey: segment)
            } else {
                let child = map[segment].flatMap { Json.normalized($0) } ?? emptyContainer(forNextSegment: remaining.first)
                map[segment] = try writing(value, into: child, segments: remaining, path: path, padding: &padding)
            }
            return map
        }

        if var list = current as? JsonArray {
            let index: Int
            if segment == "-" {
                index = list.count
            } else if let parsed = arrayIndex(segment) {
                index = parsed
            } else {
                throw DataModelError.invalidArrayIndex(segment, path: path)
            }
            guard index <= Self.maxArrayIndex, index - list.count <= padding else {
                throw DataModelError.invalidArrayIndex(segment, path: path)
            }
            padding -= max(index - list.count, 0)
            if remaining.isEmpty, value == nil {
                if index < list.count { list[index] = NSNull() }
                return list
            }
            let existing = index < list.count ? Json.normalized(list[index]) : nil
            let child = existing ?? emptyContainer(forNextSegment: remaining.first)
            let written = try writing(value, into: child, segments: remaining, path: path, padding: &padding)
            // Writing past the end pads the gap with nulls.
            while list.count < index {
                list.append(NSNull())
            }
            if index < list.count {
                list[index] = written
            } else {
                list.append(written)
            }
            return list
        }

        throw DataModelError.notAContainer(path)
    }

    // The largest array index a write may use, so one write can't allocate an enormous array.
    static let maxArrayIndex = 10000

    /// Parses an RFC 6901 array index: digits without leading zeros.
    private static func arrayIndex(_ segment: String) -> Int? {
        guard !segment.isEmpty, segment.allSatisfy(\.isASCII), segment.allSatisfy(\.isNumber) else { return nil }
        guard segment == "0" || !segment.hasPrefix("0") else { return nil }
        return Int(segment)
    }

    private static func emptyContainer(forNextSegment segment: String?) -> (any Sendable)? {
        guard let segment else { return nil }
        return arrayIndex(segment) != nil || segment == "-" ? JsonArray() : JsonMap()
    }
}

/// A data model write that could not be applied.
@available(iOS 15.0, macOS 12.0, *)
enum DataModelError: Error, Equatable, CustomStringConvertible {
    /// The path descends through a value that is neither an object nor an array.
    case notAContainer(DataPath)

    /// An array was addressed with a segment that is not a valid index.
    case invalidArrayIndex(String, path: DataPath)

    /// The root of the data model was set to something other than an object.
    case invalidRoot

    /// The path has more segments than the data model nests.
    case pathTooDeep(DataPath)

    /// A human-readable description of the failure.
    var description: String {
        switch self {
        case let .notAContainer(path):
            return "Cannot set path '\(path)' because it descends through a value that is not an object or an array."
        case let .invalidArrayIndex(segment, path):
            return "Cannot set path '\(path)': '\(segment)' is a non-numeric segment or out of bounds for an array."
        case .invalidRoot:
            return "The data model root must be an object."
        case let .pathTooDeep(path):
            return "Cannot set path '\(path)': it is deeper than \(A2UIProtocol.maxNestingDepth) levels."
        }
    }
}
