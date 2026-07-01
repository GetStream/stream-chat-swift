//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A role that can be mentioned in a channel to notify users assigned to it.
///
/// Roles can be either app-level (global) or channel-specific.
public struct Role: Equatable, Identifiable, Sendable {
    /// The unique name of the role (e.g. `admin`, `moderator`). Also used as the identifier.
    public let name: String

    /// Whether the role is a custom role defined for the application.
    public let isCustom: Bool

    /// The permission scopes the role applies to.
    public let scopes: [String]

    /// The date when the role was created, when available.
    public let createdAt: Date?

    /// The date when the role was last updated, when available.
    public let updatedAt: Date?

    public var id: String { name }

    init(
        name: String,
        isCustom: Bool = false,
        scopes: [String] = [],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.name = name
        self.isCustom = isCustom
        self.scopes = scopes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Response -> Model

extension RolePayload {
    func asModel() -> Role {
        Role(
            name: name,
            isCustom: custom,
            scopes: scopes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
