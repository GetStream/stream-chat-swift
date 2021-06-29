//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ChatClientConfig_Tests: XCTestCase {
    func test_maxAttachmentSize_whenNoCustomCDNClient_takesMaxSizeFromDefaultCDNClient() {
        // Create a config without custom CDN client.
        let config = ChatClientConfig(apiKey: .init(.unique))
        
        // Assert max size from default CDN client is used.
        XCTAssertEqual(config.maxAttachmentSize, StreamCDNClient.maxAttachmentSize)
    }
    
    func test_maxAttachmentSize_whenCustomCDNClientSet_takesMaxSizeFromCustomCDNClient() {
        class CustomCDNClient: CDNClient {
            static var maxAttachmentSize: Int64 { 10 * 1000 * 1000 }
            
            func uploadAttachment(
                _ attachment: AnyChatMessageAttachment,
                progress: ((Double) -> Void)?,
                completion: @escaping (Result<URL, Error>) -> Void
            ) {}
        }
        
        // Create a config.
        var config = ChatClientConfig(apiKey: .init(.unique))
        
        // Set custom CDN client.
        config.customCDNClient = CustomCDNClient()
        
        // Assert max size from custom CDN client is used.
        XCTAssertEqual(config.maxAttachmentSize, CustomCDNClient.maxAttachmentSize)
    }
}
