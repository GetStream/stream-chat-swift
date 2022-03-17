//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of `InternetConnection`
final class InternetConnectionMock: InternetConnection {
    private(set) var monitorMock: InternetConnectionMonitorMock!
    private(set) var init_notificationCenter: NotificationCenter!

    init(
        monitor: InternetConnectionMonitorMock = .init(),
        notificationCenter: NotificationCenter = .default
    ) {
        super.init(notificationCenter: notificationCenter, monitor: monitor)
        init_notificationCenter = notificationCenter
        monitorMock = monitor
    }
}

/// Mock implementation of `InternetConnectionMonitor`
final class InternetConnectionMonitorMock: InternetConnectionMonitor {
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
