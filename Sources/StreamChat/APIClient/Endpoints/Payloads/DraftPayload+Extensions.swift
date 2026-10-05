//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Generated properties are slightly different from the previously hand-written ones.
extension DraftMessagePayload {
    var command: String? { custom[MessageResponse.CodingKeys.command.rawValue]?.stringValue }
    var args: String? { custom["args"]?.stringValue }
}
