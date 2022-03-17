//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

final class ConfirmButton_Tests: XCTestCase {
    private lazy var container = UIView().withoutAutoresizingMaskConstraints

    override func setUp() {
        super.setUp()
        container.subviews.forEach { $0.removeFromSuperview() }
    }

    func test_defaultAppearance() {
        let view = ConfirmButton().withoutAutoresizingMaskConstraints
        container.embed(view)

        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-disabled")
    }

    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.images.confirmCheckmark = TestImages.vader.image.tinted(with: .systemPink)!
        appearance.colorPalette.inactiveTint = .black

        let view = ConfirmButton().withoutAutoresizingMaskConstraints
        view.appearance = appearance

        container.embed(view)

        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-disabled")
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ConfirmButton {
            override func setUpAppearance() {
                setTitle("🥪", for: .normal)
                setTitle("🤷🏻‍♂️", for: .disabled)
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints

        container.embed(view)
        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-disabled")
    }
}
