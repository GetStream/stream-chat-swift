//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

// Application
let app = XCUIApplication()

class StreamTestCase: XCTestCase {

    let deviceRobot = DeviceRobot()
    var userRobot = UserRobot()
    var participantRobot: ParticipantRobot!
    var server: StreamMockServer!

    override func setUpWithError() throws {
        continueAfterFailure = false
        server = StreamMockServer()
        server.configure()
        server.start(port: in_port_t(MockServerConfiguration.port))
        participantRobot = ParticipantRobot(server)

        try super.setUpWithError()

        useMockServer()
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        server.stop()
        server = nil
        
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
}
