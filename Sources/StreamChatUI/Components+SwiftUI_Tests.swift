//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import SwiftUI
import XCTest

@available(iOS 13, *)
class Components_SwiftUI_Tests: iOS13TestCase {
    func test_correctInstanceIsUsed() {
        class TestView: UIView, MaskProviding {
            var maskingPath: CGPath? { nil }
        }

        var referenceComponents = Components()
        referenceComponents.onlineIndicatorView = TestView.self

        var usedComponents: Components.ObservableObject?

        struct ComponentsSpyView: View {
            @EnvironmentObject var components: Components.ObservableObject
            let componentsCallback: (Components.ObservableObject) -> Void
            var body: some View {
                componentsCallback(components)
                return Text("I am your father!")
            }
        }

        // Simulate the view is used
        let view = ComponentsSpyView { usedComponents = $0 }
            .setUpStreamChatComponents(referenceComponents)
        view.simulateViewAddedToHierarchy()

        // Assert the correct Components is used
        AssertAsync.willBeTrue(usedComponents?.onlineIndicatorView is TestView.Type)
    }
}
