//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension Appearance {
    struct Formatters {
        /// A formatter that converts the message date separator used in the message list to textual representation.
        public var messageTimestamp: MessageTimestampFormatter = DefaultMessageTimestampFormatter()

        /// A formatter that converts the message date separator to textual representation.
        /// This formatter is used to display the message date between each group of messages
        /// and the top date overlay in the message list.
        public var messageDateSeparator: MessageDateSeparatorFormatter = DefaultMessageDateSeparatorFormatter()

        /// A formatter that converts the time a user was last active to textual representation.
        public var userLastActivity: UserLastActivityFormatter = DefaultUserLastActivityFormatter()

        /// A formatter that converts the video duration to textual representation.
        public var videoDuration: VideoDurationFormatter = DefaultVideoDurationFormatter()

        /// A formatter that converts the progress percentage to textual representation.
        public var uploadingProgress: UploadingProgressFormatter = DefaultUploadingProgressFormatter()

        /// A formatter that generates a name for the given channel.
        public var channelName: ChannelNameFormatter = DefaultChannelNameFormatter()
    }
}
