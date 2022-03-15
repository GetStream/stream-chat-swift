//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class SwipeableView_Tests: XCTestCase {
    func test_defaultAppearance() {
        // Create SwipeableView
        let view = SwipeableView().withoutAutoresizingMaskConstraints

        // Simulate the delete and more buttons default behavior:
        let (deleteView, moreView) = testViews(moreAction: {}, deleteAction: {})
        view.actionItemsStackView.addArrangedSubview(deleteView)
        view.actionItemsStackView.addArrangedSubview(moreView)
        view.addSizeConstraints()
        
        // Simulate view moving to superview to have view initialized.
        view.executeLifecycleMethods()
        
        // Buttons are revealed after swipe gesture so we need to simulate it to check the buttons.
        view.swipeOpen()
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    private func testViews(
        moreAction: @escaping (() -> Void),
        deleteAction: @escaping (() -> Void)
    ) -> (UIView, UIView) {
        let testButton2 = UIButton().withoutAutoresizingMaskConstraints

        testButton2.backgroundColor = Appearance.default.colorPalette.alert
        testButton2.tintColor = .white

        let testButton1 = UIButton().withoutAutoresizingMaskConstraints

        testButton1.backgroundColor = Appearance.default.colorPalette.background1
        testButton1.tintColor = Appearance.default.colorPalette.text

        let deleteView = CellActionView().withoutAutoresizingMaskConstraints
        deleteView.actionButton = testButton2

        let moreActionsView = CellActionView().withoutAutoresizingMaskConstraints
        moreActionsView.actionButton = testButton1

        return (moreActionsView, deleteView)
    }
}

private extension SwipeableView {
    func swipeOpen() {
        actionStackViewWidthConstraint?.constant = 100
    }
    
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
            widthAnchor.constraint(equalToConstant: 150)
        ])
    }
}
