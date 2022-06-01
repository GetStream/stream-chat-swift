//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessageAttachmentPayload {
    static func dummy(
        type: AttachmentType = .image,
        title: String = .unique,
        url: URL = URL(string: "https://getstream.io/some.jpg")!,
        imageURL: URL = URL(string: "https://getstream.io/some.jpg")!,
        imagePreviewURL: URL = URL(string: "https://getstream.io/some_preview.jpg")!,
        file: AttachmentFile = .init(type: .gif, size: 1024, mimeType: "image/gif")
    ) -> MessageAttachmentPayload {
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
        
        return try! JSONDecoder.default.decode(MessageAttachmentPayload.self, from: data)
    }
    
    var decodedImagePayload: ImageAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(payload)
        return try? JSONDecoder.stream.decode(ImageAttachmentPayload.self, from: data)
    }

    var decodedFilePayload: FileAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(payload)
        return try? JSONDecoder.stream.decode(FileAttachmentPayload.self, from: data)
    }
    
    var decodedGiphyPayload: GiphyAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(payload)
        return try? JSONDecoder.stream.decode(GiphyAttachmentPayload.self, from: data)
    }

    var decodedLinkPayload: LinkAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(payload)
        return try? JSONDecoder.stream.decode(LinkAttachmentPayload.self, from: data)
    }
    
    var decodedVideoPayload: VideoAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(payload)
        return try? JSONDecoder.stream.decode(VideoAttachmentPayload.self, from: data)
    }

    static func image(
        title: String = .unique,
        imageURL: URL = URL(string: "https://getstream.io/some.jpg")!,
        imagePreviewURL: URL = URL(string: "https://getstream.io/some_preview.jpg")!
    ) -> Self {
        .init(
            type: .image,
            payload: .dictionary([
                "title": .string(title),
                "image_url": .string(imageURL.absoluteString),
                "thumb_url": .string(imagePreviewURL.absoluteString)
            ])
        )
    }

    static func file(
        title: String = .unique,
        assetURL: URL = URL(string: "https://getstream.io/some.pdf")!,
        file: AttachmentFile = .init(type: .pdf, size: 1024, mimeType: "application/pdf")
    ) -> Self {
        .init(
            type: .file,
            payload: .dictionary([
                "title": .string(title),
                "asset_url": .string(assetURL.absoluteString),
                "mime_type": .string(file.mimeType!),
                "file_size": .string("\(file.size)")
            ])
        )
    }

    static func giphy(
        title: String = .unique,
        previewURL: URL = URL(string: "https://getstream.io/some.gif")!,
        actions: [AttachmentAction] = []
    ) -> Self {
        let actionsData = try! JSONEncoder.default.encode(actions)
        let actionsJSON = try! JSONDecoder.default.decode(RawJSON.self, from: actionsData)

        return .init(
            type: .giphy,
            payload: .dictionary([
                "title": .string(title),
                "thumb_url": .string(previewURL.absoluteString),
                "actions": actionsJSON
            ])
        )
    }

    static func link(
        title: String = .unique,
        text: String = .unique,
        author: String = .unique,
        ogURL: URL = URL(string: "https://getstream.io/some.pdf")!,
        imageURL: URL = URL(string: "https://getstream.io/some.pdf")!,
        previewURL: URL = URL(string: "https://getstream.io/some_preview.pdf")!,
        titleURL: URL = URL(string: "https://getstream.io/page")!
    ) -> Self {
        .init(
            type: .linkPreview,
            payload: .dictionary([
                "title": .string(title),
                "text": .string(text),
                "author_name": .string(author),
                "og_scrape_url": .string(ogURL.absoluteString),
                "image_url": .string(imageURL.absoluteString),
                "thumb_url": .string(previewURL.absoluteString),
                "title_link": .string(titleURL.absoluteString)
            ])
        )
    }
    
    static func video(
        title: String = .unique,
        videoURL: URL = URL(string: "https://getstream.io/video.mov")!,
        file: AttachmentFile = .init(type: .mov, size: 1024, mimeType: "video/mov")
    ) -> Self {
        .init(
            type: .video,
            payload: .dictionary([
                "title": .string(title),
                "asset_url": .string(videoURL.absoluteString),
                "mime_type": .string(file.mimeType!),
                "file_size": .string("\(file.size)")
            ])
        )
    }
}
