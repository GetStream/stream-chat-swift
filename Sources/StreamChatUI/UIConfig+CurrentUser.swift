//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public extension _UIConfig {
    struct CurrentUser {
        internal var currentUserViewAvatarView: _CurrentChatUserAvatarView<ExtraData>.Type = _CurrentChatUserAvatarView<ExtraData>
            .self
        internal var avatarView: ChatAvatarView.Type = ChatAvatarView.self
    }
}
