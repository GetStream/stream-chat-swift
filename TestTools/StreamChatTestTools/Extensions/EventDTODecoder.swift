//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

struct EventDTODecoder {
    func decode(from data: Data) throws -> Event {
        let event = try EventDecoder().decode(from: data)
        return (event as? WSEvent)?.rawValue ?? event
    }
}
