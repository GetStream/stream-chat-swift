//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageDeliveryStatusView_Tests: XCTestCase {
    // MARK: - Sending
    
    func test_appearance_whenMesssageInSendingState() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 10
        )
        
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            localState: .sending,
            isSentByCurrentUser: true
        )
        
        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints
        
        view.content = .init(message: message, channel: channel)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    // MARK: - Sent
    
    func test_appearance_whenMessageIsSent() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 10
        )
        
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: []
        )
        
        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints
        
        view.content = .init(message: message, channel: channel)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    // MARK: - Read
    
    func test_appearance_whenMessageIsReadInDirectMessagesChannel() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 2
        )
        
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [.mock(id: .unique)]
        )
        
        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints
        
        view.content = .init(message: message, channel: channel)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_appearance_whenMessageIsReadInGroupChannel() {
        let channel: ChatChannel = .mock(
            cid: .unique,
            config: .mock(readEventsEnabled: true),
            memberCount: 10
        )
        
        let message: ChatMessage = .mock(
            id: .unique,
            cid: channel.cid,
            text: .unique,
            author: .mock(id: .unique),
            localState: nil,
            isSentByCurrentUser: true,
            readBy: [
                .mock(id: .unique),
                .mock(id: .unique),
                .mock(id: .unique)
            ]
        )
        
        let view = ChatMessageDeliveryStatusView().withoutAutoresizingMaskConstraints
        
        view.content = .init(message: message, channel: channel)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}
