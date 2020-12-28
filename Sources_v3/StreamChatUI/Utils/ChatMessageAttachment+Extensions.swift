//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension _ChatMessageAttachment {
    /// Returns `true` if attachment has either `.image` or `.giphy` type.
    var isImageOrGIF: Bool {
        type == .image || type == .giphy
    }
}
