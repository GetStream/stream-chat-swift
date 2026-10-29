//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension BackendRobot {
    /// Enables or disables message reminders in the config of every channel.
    @discardableResult
    func setMessageReminders(enabled: Bool) -> BackendRobot {
        waitForMockServerToStart()
        _ = mockServer.postRequest(endpoint: "config/reminders?value=\(enabled)")
        return self
    }

    /// Creates a reminder for the last message of the current channel on the server side.
    /// Pass `nil` for a "saved for later" reminder without a due date.
    @discardableResult
    func createReminder(remindAtSeconds: Int? = nil) -> BackendRobot {
        var endpoint = "create_reminder"
        if let remindAtSeconds {
            endpoint += "?remind_at=\(remindAtSeconds)"
        }
        _ = mockServer.postRequest(endpoint: endpoint)
        return self
    }
}
