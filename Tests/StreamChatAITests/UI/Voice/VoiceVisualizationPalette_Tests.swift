//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import UIKit
import XCTest

final class VoiceVisualizationPalette_Tests: XCTestCase {
    func test_hsv_keepsTheFullColor() {
        let streamBlue = UIColor(red: 0, green: 95 / 255, blue: 1, alpha: 1)

        let hsv = VoiceVisualizationPalette.hsv(streamBlue)

        XCTAssertEqual(hsv.x * 360, 217.6, accuracy: 0.1)
        XCTAssertEqual(hsv.y, 1, accuracy: 1e-4)
        XCTAssertEqual(hsv.z, 1, accuracy: 1e-4)
    }

    func test_hsv_ofAMutedColor_keepsItsSaturationAndValue() {
        let muted = UIColor(hue: 0.3, saturation: 0.25, brightness: 0.6, alpha: 1)

        let hsv = VoiceVisualizationPalette.hsv(muted)

        XCTAssertEqual(hsv.x, 0.3, accuracy: 1e-4)
        XCTAssertEqual(hsv.y, 0.25, accuracy: 1e-4)
        XCTAssertEqual(hsv.z, 0.6, accuracy: 1e-4)
    }

    func test_hsv_ofAGray_hasNoSaturation() {
        let hsv = VoiceVisualizationPalette.hsv(UIColor(white: 0.5, alpha: 1))

        XCTAssertEqual(hsv.y, 0, accuracy: 1e-4)
        XCTAssertEqual(hsv.z, 0.5, accuracy: 1e-4)
    }

    func test_hsv_resolvesDynamicColorsForTheTraits() {
        let dynamic = UIColor { $0.userInterfaceStyle == .dark ? .red : .blue }

        let light = VoiceVisualizationPalette.hsv([dynamic], traits: UITraitCollection(userInterfaceStyle: .light))
        let dark = VoiceVisualizationPalette.hsv([dynamic], traits: UITraitCollection(userInterfaceStyle: .dark))

        XCTAssertEqual(light.first?.x ?? 0, 2 / 3, accuracy: 1e-4)
        XCTAssertEqual(dark.first?.x ?? 1, 0, accuracy: 1e-4)
    }

    func test_hsv_keepsTheFirstFiveColors() {
        let colors = Array(repeating: UIColor.red, count: 7)

        XCTAssertEqual(VoiceVisualizationPalette.hsv(colors, traits: UITraitCollection()).count, 5)
    }
}
