//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Constants defined by the A2UI (Agent to UI) protocol, version 1.0.
///
/// See the specification at
/// https://github.com/a2ui-project/a2ui/tree/main/specification/v1_0.
public enum A2UIProtocol {
    /// The protocol version string carried by every wire message.
    public static let version = "1.0"

    /// The key used for the version discriminator on the wire.
    public static let versionKey = "version"

    /// The id every surface's top-level component must use.
    public static let rootComponentId = "root"

    /// The reserved component type of the implicit surface container.
    public static let surfaceComponentType = "Surface"

    /// The prefix reserved for universal system functions such as `@index`.
    public static let systemFunctionPrefix = "@"

    /// The key that marks an object as a data binding.
    public static let pathKey = "@path"

    /// The key that marks an object as a function call.
    public static let callKey = "@call"

    /// The deepest component nesting a renderer must support, also the deepest a JSON value may nest.
    public static let maxNestingDepth = 50

    /// The deepest `@call`s may nest through their arguments.
    public static let maxFunctionCallDepth = 5
}

/// The wire key that identifies a surface in A2UI messages.
public let surfaceIdKey = "surfaceId"

/// The catalog id of the A2UI v1.0 basic catalog.
public let basicCatalogId = "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json"
