//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest
import MobileCoreServices
import ImageIO

// Application
let app = XCUIApplication()

class StreamTestCase: XCTestCase {

    let deviceRobot = DeviceRobot(app)
    var userRobot: UserRobot!
    var backendRobot: BackendRobot!
    var participantRobot: ParticipantRobot!
    var server: StreamMockServer!
    var timer: Timer?
    var screenShots: [XCUIScreenshot] = []

    override func setUpWithError() throws {
        continueAfterFailure = false
        server = StreamMockServer()
        server.configure()
        server.start(port: in_port_t(MockServerConfiguration.port))
        participantRobot = ParticipantRobot(server)
        backendRobot = BackendRobot(server)
        userRobot = UserRobot(server)

        try super.setUpWithError()
        alertHandler()
        useMockServer()
        server.recordVideo(name: testName)
        app.launch()
    }

    override func tearDownWithError() throws {
        attachElementTree()
        stopVideoOnTearDown()
        app.terminate()
        server.stop()
        server = nil
        backendRobot.delayServerResponse(byTimeInterval: 0.0)
        
        try super.tearDownWithError()
        app.launchArguments.removeAll()
        app.launchEnvironment.removeAll()
    }
}

extension StreamTestCase {

    private func useMockServer() {
        // Leverage web socket server
        app.setLaunchArguments(.useMockServer)

        // Configure web socket host
        app.setEnvironmentVariables([
            .websocketHost: "\(MockServerConfiguration.websocketHost)",
            .httpHost: "\(MockServerConfiguration.httpHost)",
            .port: "\(MockServerConfiguration.port)"
        ])
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
    
    private func stopVideoOnTearDown() {
        var delete = true
        
        if let testRun = testRun {
            if testRun.failureCount > 0 || testRun.unexpectedExceptionCount > 0 {
                delete = false
            }
        }
        
        server.recordVideo(name: testName, delete: delete, stop: true)
    }
    
    private var testName: String {
        String(name.split(separator: " ")[1].dropLast())
    }
}
