//
//  UIApplication+AppState.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxAppState

extension UIApplication {
    /// The current app state (see `AppState`), e.g. active, background.
    public var appState: AppState {
        switch applicationState {
        case .active:
            return .active
        case .background:
            return .background
        case .inactive:
            return .inactive
        @unknown default:
            return .terminated
        }
    }
}
