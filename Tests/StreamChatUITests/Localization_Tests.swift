//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import XCTest

final class Localization_Tests: XCTestCase {
    /// Testing bundle which should be empty.
    private var testBundle: Bundle!
    var customAppearance: Appearance = Appearance()
    
    override func setUp() {
        super.setUp()
        testBundle = Bundle(for: ThisBundle.self)
    }
    
    func test_localizationProviderAssignment_ChangesLocalizationForBundle() {
        // Set to default Appearance localizationProvider.
        Appearance.default.localizationProvider = { key, _ in
            self.testBundle.localizedString(forKey: key, value: nil, table: "TestLocalizable")
        }
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
