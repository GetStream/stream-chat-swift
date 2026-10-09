//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
import StreamCoreUI

/// The design-system configuration of the AI components.
///
/// Shared color, layout and typography tokens come from ``DesignSystemTokens``. Pass the same
/// instance into the Chat and Video appearances so all the SDKs reskin together. Colors and
/// fonts only the AI components use live on ``colors`` and ``fonts``, and their icons on
/// ``images``.
///
/// ```swift
/// let tokens = DesignSystemTokens()
/// tokens.colors.accentPrimary = .systemPurple
/// let appearance = AIAppearance(tokens: tokens)
/// appearance.colors.reasoningRule = .systemPurple
/// InjectedValues[\.aiAppearance] = appearance
/// ```
@MainActor
public final class AIAppearance {
    /// The instance the AI components use unless they are given another one.
    public nonisolated static let shared = AIAppearance()

    /// Shared color, layout and typography tokens. Mutating this instance is visible to any
    /// other appearance constructed with it.
    public let tokens: DesignSystemTokens

    /// AI-specific colors, derived from ``tokens``.
    public var colors: Colors

    /// AI-specific fonts, derived from ``tokens``.
    public var fonts: Fonts

    /// The icons the AI components render.
    public var images: Images

    /// Returns the text for a key of a strings table. Replace it to change or translate the
    /// components' texts.
    public nonisolated(unsafe) static var localizationProvider: @Sendable (_ key: String, _ table: String) -> String = { key, table in
        Bundle.streamChatAI.localizedString(forKey: key, value: nil, table: table)
    }

    public nonisolated init(
        tokens: DesignSystemTokens = DesignSystemTokens(),
        images: Images = Images()
    ) {
        self.tokens = tokens
        colors = Colors(tokens: tokens)
        fonts = Fonts(tokens: tokens)
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
