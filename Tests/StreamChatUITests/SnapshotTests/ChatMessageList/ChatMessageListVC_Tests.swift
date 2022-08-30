//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageListVC_Tests: XCTestCase {
    func test_setUp_propagatesDeletedMessagesVisabilityToResolver() {
        // GIVEN
        var config = ChatClientConfig(apiKey: .init(.unique))
        config.deletedMessagesVisibility = .alwaysHidden
        
        let sut = ChatMessageListVC()
        sut.client = ChatClient(config: config)
        sut.components = .mock
        
        XCTAssertNil(sut.components.messageLayoutOptionsResolver.config)
        
        // WHEN
        sut.setUp()
        
        // THEN
        XCTAssertEqual(
            sut.components.messageLayoutOptionsResolver.config?.deletedMessagesVisibility,
            config.deletedMessagesVisibility
        )
    }
    
    func test_rightMentionedUserIsSend_whenDidTapOnMentionedUser() {
        // GIVEN
        class CustomChatMessageListVC: ChatMessageListVC {
            var tappedMentionedUser: ChatUser?
            
            override func didTapOnMentionedUser(_ mentionedUser: ChatUser?) {
                super.didTapOnMentionedUser(mentionedUser)
                tappedMentionedUser = mentionedUser
            }
        }
        
        let sut = CustomChatMessageListVC()
        sut.client = ChatClient(config: ChatClientConfig(apiKey: .init(.unique)))
        sut.components = .mock
        
        let mentionedUser: ChatUser = .unique
        
        // WHEN
        sut.didTapOnMentionedUser(mentionedUser)
        
        // THEN
        XCTAssertEqual(mentionedUser, sut.tappedMentionedUser)
    }
}
