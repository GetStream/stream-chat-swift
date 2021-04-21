//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

public extension _UIConfig {
    struct CurrentUser {
        public var currentUserViewAvatarView: _CurrentChatUserAvatarView<ExtraData>.Type = _CurrentChatUserAvatarView<ExtraData>
            .self
        public var avatarView: ChatAvatarView.Type = ChatAvatarView.self
    }
}
