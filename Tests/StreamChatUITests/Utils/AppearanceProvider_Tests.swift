//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
@testable import StreamChatUI
import XCTest

final class AppearanceProvider_Tests: XCTestCase {
    func test_appearance_passedDownToSubview() {
        let parentView = TestAppearanceView()
        let subView = TestAppearanceView()
        var appearance = Appearance()
        // Set some random color to check if the appearance is passed down
        appearance.colorPalette.alternativeActiveTint = testColor
        
        parentView.addSubview(subView)
        parentView.appearance = appearance
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: subView.appearance.colorPalette.alternativeActiveTint),
            String(describing: appearance.colorPalette.alternativeActiveTint)
        )
    }
    
    func test_components_passedDown_ignoringNonProviders() {
        let parentView = TestAppearanceView()
        let intermediateView = UIView()
        let subView = TestAppearanceView()
        var appearance = Appearance()
        // Set some random color to check if the appearance is passed down
        appearance.colorPalette.alternativeActiveTint = testColor

        parentView.addSubview(intermediateView)
        intermediateView.addSubview(subView)
        parentView.appearance = appearance

        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: subView.appearance.colorPalette.alternativeActiveTint),
            String(describing: appearance.colorPalette.alternativeActiveTint)
        )
    }
    
    func test_components_passedDown_withoutProviders() {
        let parentView = UIView()
        let subView = TestAppearanceView()
        let defaultAppearance = Appearance.default

        parentView.addSubview(subView)

        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: subView.appearance.colorPalette.alternativeActiveTint),
            String(describing: defaultAppearance.colorPalette.alternativeActiveTint)
        )
    }

    func test_appearance_passedDownToVCView() {
        let vc = TestAppearanceViewController()
        var appearance = Appearance()
        // Set some random color to check if the appearance is passed down
        appearance.colorPalette.alternativeActiveTint = testColor

        vc.appearance = appearance

        // Force to call viewDidLoad
        vc.loadViewIfNeeded()

        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: vc.subView.appearance.colorPalette.alternativeActiveTint),
            String(describing: appearance.colorPalette.alternativeActiveTint)
        )
    }
}

private class TestAppearanceView: UIView, AppearanceProvider {}

private class TestAppearanceViewController: UIViewController, AppearanceProvider {
    let subView = TestAppearanceView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(subView)
    }
}

private var testColor = UIColor(r: 1, g: 2, b: 3)
