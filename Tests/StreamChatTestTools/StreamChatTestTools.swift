//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@_exported import StreamChatTestHelpers

public final class StreamChatTestTools {}

extension Bundle {
    public static var testTools: Bundle {
        Bundle(for: StreamChatTestTools.self)
    }
}
