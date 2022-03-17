//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import StreamChat

final class EventDecoderMock: AnyEventDecoder {
    var decode_calledWithData: Data?
    var decodedEvent: Result<Event, Error>!

    func decode(from data: Data) throws -> Event {
        decode_calledWithData = data

        switch decodedEvent {
        case let .success(event): return event
        case let .failure(error): throw error
        case .none:
            XCTFail("Undefined state, `decodedEvent` should not be nil")
            // just dummy error to make compiler happy
            throw NSError(domain: "some error", code: 0, userInfo: nil)
        }
    }
}
