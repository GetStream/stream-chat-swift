//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension EventDecoder {
    /// Decodes the event and unwraps the generated event model from `WSEvent`.
    func decodeDTO(from data: Data) throws -> Event {
        let event = try decode(from: data)
        return (event as? WSEvent)?.rawValue ?? event
    }
}
