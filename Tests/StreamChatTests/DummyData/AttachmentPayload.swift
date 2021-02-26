//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension AttachmentPayload {
    static func dummy(
        type: AttachmentType = .image,
        title: String = .unique,
        url: URL = URL(string: "https://getstream.io/some.jpg")!,
        imageURL: URL = URL(string: "https://getstream.io/some.jpg")!,
        imagePreviewURL: URL = URL(string: "https://getstream.io/some_preview.jpg")!,
        file: AttachmentFile = .init(type: .gif, size: 1024, mimeType: "image/gif")
    ) -> AttachmentPayload {
        let data: Data = """
        {
            "type": "\(type.rawValue)",
            "image_url" : "\(imageURL.absoluteString)",
            "title" : "\(title)",
            "thumb_url" : "\(imagePreviewURL.absoluteString)",
            "url" : "\(url.absoluteString)",
            "file_size": \(file.size),
            "mime_type": "\(file.mimeType!)"
        }
        """.data(using: .utf8)!
        
        return try! JSONDecoder.default.decode(AttachmentPayload.self, from: data)
    }
    
    var decodedDefaultAttachment: ChatMessageDefaultAttachment? {
        let data = try! JSONEncoder.stream.encode(payload)
        return try? JSONDecoder.stream.decode(ChatMessageDefaultAttachment.self, from: data)
    }
    
    var decodedImageAttachment: ChatMessageImageAttachment? {
        let data = try! JSONEncoder.stream.encode(payload)
        return try? JSONDecoder.stream.decode(ChatMessageImageAttachment.self, from: data)
    }
    
    var decodedGiphyAttachment: ChatMessageGiphyAttachment? {
        let data = try! JSONEncoder.stream.encode(payload)
        return try? JSONDecoder.stream.decode(ChatMessageGiphyAttachment.self, from: data)
    }
}
