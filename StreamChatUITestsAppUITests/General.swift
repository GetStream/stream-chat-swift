//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@_exported import StreamChatTestHelpers
import Foundation

final class StreamChatUITests {}

extension Bundle {
    static var test: Bundle {
        Bundle(for: StreamChatUITests.self)
    }
}
