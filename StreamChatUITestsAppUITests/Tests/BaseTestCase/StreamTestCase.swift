//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

let app = XCUIApplication()

class StreamTestCase: XCTestCase {
    let deviceRobot = DeviceRobot(app)
    let userRobot = UserRobot()
    var backendRobot: BackendRobot!
    var participantRobot: ParticipantRobot!
    var mockServer: StreamMockServer!
    var useMockServer = true
    var switchApiKey: String?

    override func setUpWithError() throws {
        continueAfterFailure = false

        try super.setUpWithError()
        alertHandler()
        backendHandler()
        coverageHandler()
        app.launch()
    }

    override func tearDownWithError() throws {
        attachElementTree()
        app.terminate()
        if useMockServer {
            mockServer.stop()
        }

        try super.tearDownWithError()
        app.launchArguments.removeAll()
        app.launchEnvironment.removeAll()
    }
}

extension StreamTestCase {
    private func backendHandler() {
        if useMockServer {
            mockServer = StreamMockServer(driverPort: "4566", testName: testName)
            backendRobot = BackendRobot(mockServer)
            participantRobot = ParticipantRobot(mockServer)
            app.setEnvironmentVariables([
                .websocketHost: "ws://localhost",
                .httpHost: "http://localhost",
                .port: StreamMockServer.port!
            ])
            app.setLaunchArguments(.useMockServer)
        } else if let switchApiKey {
            app.setEnvironmentVariables([.customApiKey: switchApiKey])
        }
    }

    // Every test launches a fresh app process, so pointing its profile output at a per-test folder
    // yields the code this test executed. `%c` keeps counters in sync with the file, because XCTest
    // kills the app without running its exit handlers; `%m` keeps each instrumented image in its own file.
    private func coverageHandler() {
        guard let coverageDir = ProcessInfo.processInfo.environment["E2E_COVERAGE_DIR"] else { return }

        let testClass = String(describing: type(of: self))
        app.launchEnvironment["LLVM_PROFILE_FILE"] = "\(coverageDir)/\(testClass)/\(testName)/%m_%p%c.profraw"
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
