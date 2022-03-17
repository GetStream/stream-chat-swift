//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13, *)
final class Appearance_SwiftUI_Tests: iOS13TestCase {
    func test_correctInstanceIsUsed() {
        let testColor: UIColor? = UIColor(r: 4, g: 2, b: 0)

        var referenceAppearance = Appearance()
        referenceAppearance.colorPalette.alert = testColor!

        var usedAppearance: Appearance.ObservableObject?

        struct AppearanceSpyView: View {
            @EnvironmentObject var appearance: Appearance.ObservableObject
            let componentsCallback: (Appearance.ObservableObject) -> Void
            var body: some View {
                componentsCallback(appearance)
                return Text("I am your father!")
            }
        }

        // Simulate the view is used
        let view = AppearanceSpyView { usedAppearance = $0 }
            .setUpStreamChatAppearance(referenceAppearance)
        view.simulateViewAddedToHierarchy()

        // Assert the correct Components is used
        AssertAsync.willBeEqual(
            String(describing: usedAppearance?.colorPalette.alert),
            String(describing: testColor)
        )
    }
}

@available(iOS 13.0, *)
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
