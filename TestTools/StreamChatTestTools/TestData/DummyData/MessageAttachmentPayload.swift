//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension Attachment {
    static func dummy(
        type: AttachmentType = .image,
        title: String = .unique,
        url: URL = URL(string: "https://getstream.io/some.jpg")!,
        imageURL: URL = URL(string: "https://getstream.io/some.jpg")!,
        imageThumbnailURL: URL = URL(string: "https://getstream.io/some_preview.jpg")!,
        file: AttachmentFile = .init(type: .gif, size: 1024, mimeType: "image/gif")
    ) -> Attachment {
        let data: Data = """
        {
            "type": "\(type.rawValue)",
            "image_url" : "\(imageURL.absoluteString)",
            "title" : "\(title)",
            "thumb_url" : "\(imageThumbnailURL.absoluteString)",
            "url" : "\(url.absoluteString)",
            "file_size": \(file.size),
            "mime_type": "\(file.mimeType!)",
            "custom": {}
        }
        """.data(using: .utf8)!

        return try! JSONDecoder.default.decode(Attachment.self, from: data)
    }

    var decodedImagePayload: ImageAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(self)
        return try? JSONDecoder.stream.decode(ImageAttachmentPayload.self, from: data)
    }

    var decodedFilePayload: FileAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(self)
        return try? JSONDecoder.stream.decode(FileAttachmentPayload.self, from: data)
    }

    var decodedGiphyPayload: GiphyAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(self)
        return try? JSONDecoder.stream.decode(GiphyAttachmentPayload.self, from: data)
    }

    var decodedLinkPayload: LinkAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(self)
        return try? JSONDecoder.stream.decode(LinkAttachmentPayload.self, from: data)
    }

    var decodedVideoPayload: VideoAttachmentPayload? {
        let data = try! JSONEncoder.stream.encode(self)
        return try? JSONDecoder.stream.decode(VideoAttachmentPayload.self, from: data)
    }

    static func image(
        title: String = .unique,
        imageURL: URL = URL(string: "https://getstream.io/some.jpg")!,
        imagePreviewURL: URL = URL(string: "https://getstream.io/some_preview.jpg")!
    ) -> Self {
        Attachment(
            custom: [:],
            imageUrl: imageURL.absoluteString,
            thumbUrl: imagePreviewURL.absoluteString,
            title: title,
            type: "image"
        )
    }

    static func file(
        title: String = .unique,
        assetURL: URL = URL(string: "https://getstream.io/some.pdf")!,
        file: AttachmentFile = .init(type: .pdf, size: 1024, mimeType: "application/pdf")
    ) -> Self {
        Attachment(
            custom: [
                "mime_type": .string(file.mimeType ?? ""),
                "file_size": .number(Double(file.size))
            ],
            assetUrl: assetURL.absoluteString,
            type: "file"
        )
    }

    static func giphy(
        title: String = .unique,
        previewURL: URL = URL(string: "https://getstream.io/some.gif")!,
        actions: [AttachmentAction] = []
    ) -> Self {
        let actionsData = try! JSONEncoder.default.encode(actions)
        let actionsJSON = try! JSONDecoder.default.decode(RawJSON.self, from: actionsData)

        return Attachment(
            custom: ["actions": actionsJSON],
            thumbUrl: previewURL.absoluteString,
            title: title,
            type: "giphy"
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
        Attachment(
            custom: [:],
            authorName: author,
            imageUrl: imageURL.absoluteString,
            ogScrapeUrl: ogURL.absoluteString,
            thumbUrl: previewURL.absoluteString,
            title: title,
            titleLink: titleURL.absoluteString,
            type: "linkPreview"
        )
    }

    static func video(
        title: String = .unique,
        videoURL: URL = URL(string: "https://getstream.io/video.mov")!,
        file: AttachmentFile = .init(type: .mov, size: 1024, mimeType: "video/mov")
    ) -> Self {
        return Attachment(
            custom: [
                "mime_type": .string(file.mimeType ?? ""),
                "file_size": .number(Double(file.size))
            ],
            assetUrl: videoURL.absoluteString,
            title: title,
            type: "video"
        )
    }

    static func audio(
        title: String = .unique,
        audioURL: URL = URL(string: "https://getstream.io/audio.mp3")!,
        file: AttachmentFile = .init(type: .mov, size: 1024, mimeType: "audio/mp3")
    ) -> Self {
        return Attachment(
            custom: [
                "mime_type": .string(file.mimeType ?? ""),
                "file_size": .number(Double(file.size))
            ],
            assetUrl: audioURL.absoluteString,
            title: title,
            type: "audio"
        )
    }

    static func voiceRecording(
        title: String = .unique,
        audioURL: URL = URL(string: "https://getstream.io/recording.aac")!,
        file: AttachmentFile = .init(type: .mov, size: 1024, mimeType: "audio/aac")
    ) -> Self {
        return Attachment(
            custom: [
                "mime_type": .string(file.mimeType ?? ""),
                "file_size": .number(Double(file.size))
            ],
            assetUrl: audioURL.absoluteString,
            title: title,
            type: "voiceRecording"
        )
    }
}
