//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Configuration for the enhanced `@mention` suggestions in the composer.
///
/// Used by ``EnhancedMentionSuggestionsProvider`` to decide which mention types
/// are surfaced and how user suggestions are searched.
public struct MentionSuggestionsConfig: Sendable {
    /// The set of mention types that can be suggested.
    ///
    /// Defaults to `[.user]` to preserve the historical behaviour where only
    /// users are suggested. Add `.here`, `.channel`, `.role` and `.group` to
    /// enable the enhanced mention suggestions.
    public var allowedMentionTypes: Set<MentionType>

    /// When `true`, user suggestions are searched across all app users instead
    /// of only the channel's members and watchers.
    public var mentionAllAppUsers: Bool

    public init(
        allowedMentionTypes: Set<MentionType> = [.user],
        mentionAllAppUsers: Bool = false
    ) {
        self.allowedMentionTypes = allowedMentionTypes
        self.mentionAllAppUsers = mentionAllAppUsers
    }

    /// The default configuration (user mentions only).
    public static let `default` = MentionSuggestionsConfig()

    /// A configuration that enables all enhanced mention types.
    public static let enhanced = MentionSuggestionsConfig(
        allowedMentionTypes: MentionType.allBuiltIn
    )
}
