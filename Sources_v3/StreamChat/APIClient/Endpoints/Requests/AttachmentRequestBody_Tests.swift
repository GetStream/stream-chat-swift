//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class AttachmentRequestBody_Tests: XCTestCase {
    func test_body_isBuiltAndEncodedCorrectly() throws {
        let type: AttachmentType = .giphy
        let title: String = .unique
        let url: URL? = URL(string: "https://getstream.io")
        let file: AttachmentFile = .init(type: .gif, size: 1024, mimeType: "gif")
        
        // Build the body.
        let body = AttachmentRequestBody<NoExtraData.Attachment>(
            type: type,
            title: title,
            url: url,
            imageURL: url,
            file: file,
            extraData: .defaultValue
        )
    
        // Encode the body.
        let json = try JSONEncoder.default.encode(body)
        
        // Assert encoding is correct.
        AssertJSONEqual(json, [
            "type": type.rawValue!,
            "title": title,
            "asset_url": url!,
            "image_url": url!,
            "mime_type": file.mimeType!,
            "file_size": file.size
        ])
    }
}
