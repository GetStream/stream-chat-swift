//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum MockServerConfiguration {
    static var port = Int.random(in: 61000..<62000)
    static var websocketHost = "ws://localhost"
    static var httpHost = "http://localhost"
}

enum EnvironmentVariable: String {

    // This changes the base url to localhost with assigned port.
    // Two conditions need to be met in order to leverage the web socket server in LLC.
    //   1. App runs in Debug build configuration
    //   2. `USE_MOCK_SERVER` is set as launch argument
    case websocketHost = "MOCK_SERVER_WEBSOCKET_HOST"
    case httpHost = "MOCK_SERVER_HTTP_HOST"
    case port = "MOCK_SERVER_PORT"
}

enum LaunchArgument: String {
    case useMockServer = "USE_MOCK_SERVER"
}

extension ProcessInfo {
    static func contains(_ argument: LaunchArgument) -> Bool {
        processInfo.arguments.contains(argument.rawValue)
    }

    static subscript(_ environmentVariable: EnvironmentVariable) -> String? {
        processInfo.environment[environmentVariable.rawValue]
    }
}

extension XCUIApplication {
    func setLaunchArguments(_ args: LaunchArgument...) {
        launchArguments.append(contentsOf: args.map { $0.rawValue })
    }

    func setEnvironmentVariables(_ envVars: [EnvironmentVariable: String]) {
        envVars.forEach { envVar in
            launchEnvironment[envVar.key.rawValue] = envVar.value
        }
    }
}
