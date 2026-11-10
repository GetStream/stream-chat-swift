//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A scoped view into a ``DataModel``.
///
/// The A2UI specification defines two scopes: the root scope, where all
/// bindings are absolute, and collection scopes created by list templates,
/// where relative bindings resolve against the current item. A `DataContext`
/// captures the active scope plus the iteration index that the `@index` system
/// function reads.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
struct DataContext {
    /// The data model this context reads from and writes to.
    let model: DataModel

    /// The absolute path that relative bindings resolve against.
    let scopePath: DataPath

    /// The zero-based index of the current item, when inside a collection scope.
    let itemIndex: Int?

    /// Creates a context rooted at the given path.
    /// Pass `"/"` for the root scope.
    init(_ model: DataModel, _ path: String = "/", itemIndex: Int? = nil) {
        self.model = model
        self.scopePath = DataPath(path)
        self.itemIndex = itemIndex
    }

    /// Creates a context rooted at the given path.
    /// Use this when descending into a collection scope.
    init(model: DataModel, scopePath: DataPath, itemIndex: Int? = nil) {
        self.model = model
        self.scopePath = scopePath
        self.itemIndex = itemIndex
    }

    /// Whether this context is a collection scope created by a list template.
    var isCollectionScope: Bool {
        itemIndex != nil
    }

    /// Resolves a possibly relative path against this scope.
    /// Absolute paths are returned unchanged.
    func resolve(_ path: DataPath) -> DataPath {
        path.isAbsolute ? path : scopePath.appending(path)
    }

    /// Reads the value at a possibly relative path.
    /// Returns `nil` when the resolved path does not exist.
    func value(at path: DataPath) -> (any Sendable)? {
        model.value(at: resolve(path))
    }

    /// Writes a value at a possibly relative path.
    /// Passing `nil` removes the entry.
    func update(_ path: DataPath, _ value: (any Sendable)?) {
        model.update(at: resolve(path), value: value)
    }

    /// Creates a child scope for one item of a bound collection.
    /// The item index becomes visible to the `@index` function.
    func collectionScope(path: DataPath, index: Int) -> DataContext {
        DataContext(
            model: model,
            scopePath: resolve(path).appending(segment: String(index)),
            itemIndex: index
        )
    }
}
