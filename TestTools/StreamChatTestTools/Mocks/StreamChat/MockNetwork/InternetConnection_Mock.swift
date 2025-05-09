//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of `InternetConnection`
final class InternetConnection_Mock: InternetConnection, @unchecked Sendable {
    @Atomic private(set) var monitorMock: InternetConnectionMonitor_Mock!
    @Atomic private(set) var init_notificationCenter: NotificationCenter!

    init(
        monitor: InternetConnectionMonitor_Mock = .init(),
        notificationCenter: NotificationCenter = .default
    ) {
        super.init(notificationCenter: notificationCenter, monitor: monitor)
        init_notificationCenter = notificationCenter
        monitorMock = monitor
    }
}

/// Mock implementation of `InternetConnectionMonitor`
final class InternetConnectionMonitor_Mock: InternetConnectionMonitor, @unchecked Sendable {
    weak var delegate: InternetConnectionDelegate?

    var status: InternetConnection.Status = .unknown {
        didSet {
            delegate?.internetConnectionStatusDidChange(status: status)
        }
    }

    var isStarted = false

    func start() {
        isStarted = true
        status = .available(.great)
    }

    func stop() {
        isStarted = false
        status = .unknown
    }
}
