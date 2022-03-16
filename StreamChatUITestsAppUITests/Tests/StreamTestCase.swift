//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

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
        app.setLaunchArguments(.useMockServer)
        app.setEnvironmentVariables([
            .websocketHost: "\(MockServerConfiguration.websocketHost)",
            .httpHost: "\(MockServerConfiguration.httpHost)",
            .port: "\(MockServerConfiguration.port)"
        ])
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        server.clearMessageDetails()
        server.stop()
        server = nil
        
        try super.tearDownWithError()
        app.launchArguments.removeAll()
        app.launchEnvironment.removeAll()
    }
    
}
