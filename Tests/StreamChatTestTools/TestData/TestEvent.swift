//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public struct TestEvent: Event, Equatable {
    let uuid: UUID = .init()
}
