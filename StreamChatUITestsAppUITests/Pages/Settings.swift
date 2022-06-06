//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum Settings: String {
    case showsConnectivity
    case setConnectivity
    case isConnected
    case isLocalStorageEnabled

    var element: XCUIElement { app.switches[rawValue] }
}
