//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import XCTest

let app = XCUIApplication()

class StreamTestCase: XCTestCase {
    let deviceRobot = DeviceRobot(app)
    var userRobot: UserRobot!
    var backendRobot: BackendRobot!
    var participantRobot: ParticipantRobot!
    var mockServer: StreamMockServer!
    var useMockServer = true
    var switchApiKey: String?

    override func setUpWithError() throws {
        continueAfterFailure = false

        try super.setUpWithError()
        mockServer = StreamMockServer(driverPort: "4566", testName: testName)
        backendRobot = BackendRobot(mockServer)
        participantRobot = ParticipantRobot(mockServer)
        userRobot = UserRobot(mockServer)
        alertHandler()
        backendHandler()
        app.launch()
    }

    override func tearDownWithError() throws {
        attachElementTree()
        app.terminate()
        mockServer.stop()

        try super.tearDownWithError()
        app.launchArguments.removeAll()
        app.launchEnvironment.removeAll()
    }
}

extension StreamTestCase {
    private func backendHandler() {
        app.setEnvironmentVariables([
            .websocketHost: "ws://localhost",
            .httpHost: "http://localhost",
            .port: StreamMockServer.port!
        ])
        
        if useMockServer {
            app.setLaunchArguments(.useMockServer)
        } else if let switchApiKey {
            app.setEnvironmentVariables([.customApiKey: switchApiKey])
        }
    }

    private func attachElementTree() {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }

    private func alertHandler() {
        let title = "Push Notification Alert"
        _ = addUIInterruptionMonitor(withDescription: title) { (alert: XCUIElement) -> Bool in
            let allowButton = alert.buttons["Allow"]
            if allowButton.exists {
                allowButton.tap()
                return true
            }
            return false
        }
    }

    private func isTestFailed() -> Bool {
        if let testRun = testRun {
            let failureCount = testRun.failureCount + testRun.unexpectedExceptionCount
            return failureCount > 0
        }
        return false
    }

    private var testName: String {
        String(name.split(separator: " ")[1].dropLast())
    }
}
