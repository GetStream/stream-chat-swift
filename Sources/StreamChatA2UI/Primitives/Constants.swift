//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Constants defined by the A2UI (Agent to UI) protocol, version 1.0.
///
/// See the specification at
/// https://github.com/a2ui-project/a2ui/tree/main/specification/v1_0.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIProtocol {
    /// The protocol version string carried by every wire message.
    static let version = "1.0"

    /// The key used for the version discriminator on the wire.
    static let versionKey = "version"

    /// The id every surface's top-level component must use.
    static let rootComponentId = "root"

    /// The reserved component type of the implicit surface container.
    static let surfaceComponentType = "Surface"

    /// The prefix reserved for universal system functions such as `@index`.
    static let systemFunctionPrefix = "@"

    /// The key that marks an object as a data binding.
    static let pathKey = "@path"

    /// The key that marks an object as a function call.
    static let callKey = "@call"

    /// The deepest component nesting a renderer must support, also the deepest a JSON value may nest.
    static let maxNestingDepth = 50

    /// The deepest `@call`s may nest through their arguments.
    static let maxFunctionCallDepth = 5
}

/// The wire key that identifies a surface in A2UI messages.
@available(iOS 15.0, macOS 12.0, *)
let surfaceIdKey = "surfaceId"

/// The catalog id of the A2UI v1.0 basic catalog.
@available(iOS 15.0, macOS 12.0, *)
let basicCatalogId = "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json"
