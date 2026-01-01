//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

final class PollCreationVC_Tests: XCTestCase {
    var mockChannelController = ChatChannelController_Spy(client: .mock)

    func test_appearance() {
        let pollCreationVC = PollCreationVC(channelController: mockChannelController)
        AssertSnapshot(pollCreationVC, isEmbeddedInNavigationController: true)
    }

    func test_appearance_whenFeaturesNotSupported() {
        let pollCreationVC = PollCreationVC(channelController: mockChannelController)
        pollCreationVC.components.pollsConfig = .init(
            multipleVotes: .init(configurable: false, defaultValue: false),
            anonymousPoll: .init(configurable: false, defaultValue: false),
            suggestAnOption: .init(configurable: false, defaultValue: false),
            addComments: .init(configurable: false, defaultValue: false),
            maxVotesPerPerson: .init(configurable: false, defaultValue: false)
        )
        AssertSnapshot(
            pollCreationVC,
            isEmbeddedInNavigationController: true,
            variants: .onlyUserInterfaceStyles
        )
    }

    func test_appearance_whenFeaturesEnabledByDefault() {
        let pollCreationVC = PollCreationVC(channelController: mockChannelController)
        pollCreationVC.components.pollsConfig = .init(
            multipleVotes: .init(configurable: true, defaultValue: true),
            anonymousPoll: .init(configurable: true, defaultValue: true),
            suggestAnOption: .init(configurable: true, defaultValue: true),
            addComments: .init(configurable: true, defaultValue: true),
            maxVotesPerPerson: .init(configurable: true, defaultValue: true)
        )
        AssertSnapshot(
            pollCreationVC,
            isEmbeddedInNavigationController: true,
            variants: .onlyUserInterfaceStyles
        )
    }

    func test_appearance_whenMaxVotesOnlyDisabled() {
        let pollCreationVC = PollCreationVC(channelController: mockChannelController)
        pollCreationVC.components.pollsConfig = .init(
            multipleVotes: .init(configurable: true, defaultValue: true),
            anonymousPoll: .init(configurable: true, defaultValue: true),
            suggestAnOption: .init(configurable: true, defaultValue: true),
            addComments: .init(configurable: true, defaultValue: true),
            maxVotesPerPerson: .init(configurable: false, defaultValue: false)
        )
        AssertSnapshot(
            pollCreationVC,
            isEmbeddedInNavigationController: true,
            variants: .onlyUserInterfaceStyles
        )
    }

    func test_appearance_whenCanCreatePoll() {
        let pollCreationVC = PollCreationVC(channelController: mockChannelController)
        pollCreationVC.name = "Some poll"
        pollCreationVC.options = ["1", "2", ""]
        AssertSnapshot(
            pollCreationVC,
            isEmbeddedInNavigationController: true,
            variants: .onlyUserInterfaceStyles
        )
    }

    func test_appearance_withErrors() {
        let pollCreationVC = PollCreationVC(channelController: mockChannelController)
        pollCreationVC.name = "Some poll"
        pollCreationVC.options = ["1", "2", "1", ""]
        pollCreationVC.components.pollsConfig.multipleVotes.defaultValue = true
        pollCreationVC.components.pollsConfig.maxVotesPerPerson.defaultValue = true
        pollCreationVC.maximumVotesText = "30"
        pollCreationVC.maximumVotesErrorText = "Type a number from 1 and 10"
        AssertSnapshot(
            pollCreationVC,
            isEmbeddedInNavigationController: true
        )
    }

    func test_canCreatePoll_whenMaximumVotesError_shouldReturnFalse() {
        let pollCreationVC = PollCreationVC(channelController: mockChannelController)
        pollCreationVC.name = "Some poll"
        pollCreationVC.options = ["1", "2", ""]
        pollCreationVC.maximumVotesErrorText = "Type a number from 1 and 10"
        XCTAssertFalse(pollCreationVC.canCreatePoll)
    }

    func test_canCreatePoll_whenOptionsError_shouldReturnFalse() {
        let pollCreationVC = PollCreationVC(channelController: mockChannelController)
        pollCreationVC.name = "Some poll"
        pollCreationVC.options = ["1", "2", "1", ""]
        pollCreationVC.updateContent()
        XCTAssertFalse(pollCreationVC.canCreatePoll)
    }
}
