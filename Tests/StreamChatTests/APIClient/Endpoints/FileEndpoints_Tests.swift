//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class FileEndpoints_Tests: XCTestCase {
    func test_deleteFile_buildsCorrectly() {
        // Given
        let channelId: ChannelId = .unique
        let url = "https://example.com/someimage.pdf"
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .deleteFile(channelId.apiPath),
            method: .delete,
            queryItems: ["url": url],
            requiresConnectionId: false,
            requiresToken: true
        )
        
        // When
        let endpoint: Endpoint<EmptyResponse> = .deleteFile(cid: channelId, url: url)
        
        // Then
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(channelId.apiPath)/file", endpoint.path.value)
    }
    
    func test_deleteImage_buildsCorrectly() {
        // Given
        let channelId: ChannelId = .unique
        let url = "https://example.com/someimage.pdf"
        let expectedEndpoint = Endpoint<EmptyResponse>(
            path: .deleteImage(channelId.apiPath),
            method: .delete,
            queryItems: ["url": url],
            requiresConnectionId: false,
            requiresToken: true
        )
        
        // When
        let endpoint: Endpoint<EmptyResponse> = .deleteImage(cid: channelId, url: url)
        
        // Then
        XCTAssertEqual(AnyEndpoint(expectedEndpoint), AnyEndpoint(endpoint))
        XCTAssertEqual("channels/\(channelId.apiPath)/image", endpoint.path.value)
    }
}
