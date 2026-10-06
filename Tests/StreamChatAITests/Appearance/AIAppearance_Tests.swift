//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class AIAppearance_Tests: XCTestCase {
    private var injected: AIAppearance!

    override func setUp() {
        super.setUp()
        injected = InjectedValues[\.aiAppearance]
    }

    override func tearDown() {
        InjectedValues[\.aiAppearance] = injected
        injected = nil
        super.tearDown()
    }

    func test_colors_deriveFromTheSharedTokens() {
        let tokens = DesignSystemTokens()
        tokens.colors.accentPrimary = .systemPurple
        tokens.colors.textSecondary = .systemTeal

        let appearance = AIAppearance(tokens: tokens)

        XCTAssertEqual(appearance.colors.toolCallAccent, .systemPurple)
        XCTAssertEqual(appearance.colors.composerChatOptionText, .systemPurple)
        XCTAssertEqual(appearance.colors.reasoningTitle, .systemTeal)
        XCTAssertEqual(appearance.colors.attachmentPickerOptionDescription, .systemTeal)
    }

    func test_colors_canBeOverriddenWithoutChangingTheTokens() {
        let appearance = AIAppearance()

        appearance.colors.reasoningRule = .systemPink

        XCTAssertEqual(appearance.colors.reasoningRule, .systemPink)
        XCTAssertNotEqual(appearance.tokens.colors.borderCoreDefault, .systemPink)
    }

    func test_appearancesWithTheSameTokens_shareThem() {
        let tokens = DesignSystemTokens()
        let chat = AIAppearance(tokens: tokens)
        let other = AIAppearance(tokens: tokens)

        tokens.layout.radiusXl = 20

        XCTAssertTrue(chat.tokens === other.tokens)
        XCTAssertEqual(other.tokens.layout.radiusXl, 20)
    }

    func test_injectedAppearance_isTheSharedOneByDefault() {
        XCTAssertTrue(InjectedValues[\.aiAppearance] === AIAppearance.shared)
    }

    func test_injectedAppearance_whenReplaced_isWhatViewsRead() {
        let appearance = AIAppearance()
        appearance.colors.toolCallSuccess = .systemMint

        InjectedValues[\.aiAppearance] = appearance

        XCTAssertTrue(InjectedValues[\.aiAppearance.colors] === appearance.colors)
        XCTAssertEqual(InjectedValues[\.aiAppearance.colors].toolCallSuccess, .systemMint)
        XCTAssertTrue(InjectedValues[\.aiAppearance.tokens.fonts] === appearance.tokens.fonts)
    }
}
