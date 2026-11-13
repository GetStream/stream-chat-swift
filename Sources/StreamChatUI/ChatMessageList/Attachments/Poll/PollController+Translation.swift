//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat

extension PollController {
    /// The language to translate the poll to: the current user's language, when auto translation is enabled.
    func translationLanguage(components: Components) -> TranslationLanguage? {
        guard components.messageAutoTranslationEnabled else { return nil }
        return client.currentUserController().currentUser?.language
    }
}
