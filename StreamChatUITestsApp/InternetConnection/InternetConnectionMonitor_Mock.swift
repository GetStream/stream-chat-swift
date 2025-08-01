//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

#if TESTS
@testable import StreamChat

final class InternetConnectionMonitor_Mock: InternetConnectionMonitor, @unchecked Sendable {
    var delegate: InternetConnectionDelegate?

    var status: InternetConnection.Status = .available(.great)

    func start() {}
    func stop() {}

    func update(with status: InternetConnection.Status) {
        self.status = status
        delegate?.internetConnectionStatusDidChange(status: status)
    }
}
#endif
