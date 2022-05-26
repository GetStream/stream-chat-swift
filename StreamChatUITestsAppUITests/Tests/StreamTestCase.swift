//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import XCTest

// Application
let app = XCUIApplication()

class StreamTestCase: XCTestCase {

    let deviceRobot = DeviceRobot()
    let userRobot = UserRobot()
    var backendRobot: BackendRobot!
    var participantRobot: ParticipantRobot!
    var server: StreamMockServer!

    override func setUpWithError() throws {
        continueAfterFailure = false
        server = StreamMockServer()
        server.configure()
        server.start(port: in_port_t(MockServerConfiguration.port))
        participantRobot = ParticipantRobot(server)
        backendRobot = BackendRobot(server)

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
    
    enum Tags: String {
        case coreFeatures = "Core Features"
        case slowMode = "Slow Mode"
        case offlineSupport = "Offline Support"
        case messageDeliveryStatus = "Message Delivery Status"
    }
    
    func addTags(_ tags: [Tags]) {
        addTagsToScenario(tags.map{ $0.rawValue })
    }

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
