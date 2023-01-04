//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

enum Settings: String {
    case showsConnectivity
    case setConnectivity
    case isConnected
    case isLocalStorageEnabled
    case staysConnectedInBackground

    var element: XCUIElement { app.switches[rawValue] }
}
