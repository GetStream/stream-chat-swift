//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class Localization_Tests: XCTestCase {
    /// Testing bundle which should be empty.
    private var testBundle: Bundle!
    private var defaultLocalizationProvider: ((String, String) -> String)!

    override func setUp() {
        super.setUp()
        testBundle = Bundle(for: Self.self)
        defaultLocalizationProvider = Appearance.default.localizationProvider
        // Set to default Appearance localizationProvider.
        Appearance.default.localizationProvider = { key, _ in
            self.testBundle.localizedString(forKey: key, value: nil, table: "TestLocalizable")
        }
    }

    override func tearDown() {
        Appearance.default.localizationProvider = defaultLocalizationProvider
        super.tearDown()
    }

    func test_localizationProviderAssignment_ChangesLocalizationForBundle() {
        // Setup some component which shows localization
        let channel: ChatChannel = .mock(cid: .unique)
        let itemView = ChatChannelListItemView()
        itemView.content = .init(channel: channel, currentUserId: nil)

        // Test if the text is from bundle with different localization text for same language.
        XCTAssertEqual(
            itemView.subtitleText,
            testBundle.localizedString(forKey: "channel.item.empty-messages", value: nil, table: "TestLocalizable")
        )
    }
}
