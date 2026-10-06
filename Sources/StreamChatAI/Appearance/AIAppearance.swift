//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import StreamCoreUI

/// The design-system configuration of the AI components.
///
/// Shared color, layout and typography tokens come from ``DesignSystemTokens``. Pass the same
/// instance into the Chat and Video appearances so all the SDKs reskin together. Colors only
/// the AI components use live on ``colors``, and their icons on ``images``.
///
/// ```swift
/// let tokens = DesignSystemTokens()
/// tokens.colors.accentPrimary = .systemPurple
/// let appearance = AIAppearance(tokens: tokens)
/// appearance.colors.reasoningRule = .systemPurple
/// InjectedValues[\.aiAppearance] = appearance
/// ```
public final class AIAppearance {
    /// The instance the AI components use unless they are given another one.
    ///
    /// Not synchronized. This is a process-wide UI configuration object.
    public nonisolated(unsafe) static let shared = AIAppearance()

    /// Shared color, layout and typography tokens. Mutating this instance is visible to any
    /// other appearance constructed with it.
    public let tokens: DesignSystemTokens

    /// AI-specific colors, derived from ``tokens``.
    public var colors: Colors

    /// The icons the AI components render.
    public var images: Images

    public init(
        tokens: DesignSystemTokens = DesignSystemTokens(),
        images: Images = Images()
    ) {
        self.tokens = tokens
        colors = Colors(tokens: tokens)
        self.images = images
    }
}

enum AIAppearanceKey: InjectionKey {
    nonisolated(unsafe) static var currentValue = AIAppearance.shared
}

extension InjectedValues {
    /// Provides access to the design-system appearance of the AI components.
    public var aiAppearance: AIAppearance {
        get {
            Self[AIAppearanceKey.self]
        }
        set {
            Self[AIAppearanceKey.self] = newValue
        }
    }
}
