//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
    /// Simulates the View was added to the view hierarchy and shown on the screen
    func simulateViewAddedToHierarchy() {
        let hostingVC = UIHostingController(rootView: self)
        let window = UIWindow()
        window.rootViewController = hostingVC
        window.layoutIfNeeded()
        window.isHidden = false
    }
}
