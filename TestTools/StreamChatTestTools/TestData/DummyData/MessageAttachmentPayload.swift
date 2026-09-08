//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension MessageAttachmentPayload {
    static func dummy(
        type: AttachmentType = .image,
        title: String = .unique,
        url: URL = URL(string: "https://getstream.io/some.jpg")!,
        imageURL: URL = URL(string: "https://getstream.io/some.jpg")!,
        imageThumbnailURL: URL = URL(string: "https://getstream.io/some_preview.jpg")!,
        file: AttachmentFile = .init(type: .gif, size: 1024, mimeType: "image/gif")
    ) -> MessageAttachmentPayload {
        let data: Data = """
        {
            "type": "\(type.rawValue)",
            "image_url" : "\(imageURL.absoluteString)",
            "title" : "\(title)",
            "thumb_url" : "\(imageThumbnailURL.absoluteString)",
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
    ) -> MessageAttachmentPayload {
        MessageAttachmentPayload(
            custom: [:],
            imageUrl: imageURL.absoluteString,
            thumbUrl: imagePreviewURL.absoluteString,
            title: title,
            type: AttachmentType.image.rawValue
        )
    }

    static func file(
        title: String = .unique,
        assetURL: URL = URL(string: "https://getstream.io/some.pdf")!,
        file: AttachmentFile = .init(type: .pdf, size: 1024, mimeType: "application/pdf")
    ) -> MessageAttachmentPayload {
        MessageAttachmentPayload(
            assetUrl: assetURL.absoluteString,
            custom: [
                "mime_type": .string(file.mimeType!),
                "file_size": .string("\(file.size)")
            ],
            title: title,
            type: AttachmentType.file.rawValue
        )
    }

    static func giphy(
        title: String = .unique,
        previewURL: URL = URL(string: "https://getstream.io/some.gif")!,
        actions: [AttachmentAction] = []
    ) -> MessageAttachmentPayload {
        MessageAttachmentPayload(
            actions: actions.map {
                AttachmentActionPayload(
                    name: $0.name,
                    style: $0.style.rawValue,
                    text: $0.text,
                    type: $0.type.rawValue,
                    value: $0.value
                )
            },
            custom: [:],
            thumbUrl: previewURL.absoluteString,
            title: title,
            type: AttachmentType.giphy.rawValue
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
    ) -> MessageAttachmentPayload {
        MessageAttachmentPayload(
            authorName: author,
            custom: [:],
            imageUrl: imageURL.absoluteString,
            ogScrapeUrl: ogURL.absoluteString,
            text: text,
            thumbUrl: previewURL.absoluteString,
            title: title,
            titleLink: titleURL.absoluteString,
            type: AttachmentType.linkPreview.rawValue
        )
    }

    static func video(
        title: String = .unique,
        videoURL: URL = URL(string: "https://getstream.io/video.mov")!,
        file: AttachmentFile = .init(type: .mov, size: 1024, mimeType: "video/mov")
    ) -> MessageAttachmentPayload {
        MessageAttachmentPayload(
            assetUrl: videoURL.absoluteString,
            custom: [
                "mime_type": .string(file.mimeType!),
                "file_size": .string("\(file.size)")
            ],
            title: title,
            type: AttachmentType.video.rawValue
        )
    }

    static func audio(
        title: String = .unique,
        audioURL: URL = URL(string: "https://getstream.io/audio.mp3")!,
        file: AttachmentFile = .init(type: .mov, size: 1024, mimeType: "audio/mp3")
    ) -> MessageAttachmentPayload {
        MessageAttachmentPayload(
            assetUrl: audioURL.absoluteString,
            custom: [
                "mime_type": .string(file.mimeType!),
                "file_size": .string("\(file.size)")
            ],
            title: title,
            type: AttachmentType.audio.rawValue
        )
    }

    static func voiceRecording(
        title: String = .unique,
        audioURL: URL = URL(string: "https://getstream.io/recording.aac")!,
        file: AttachmentFile = .init(type: .mov, size: 1024, mimeType: "audio/aac")
    ) -> MessageAttachmentPayload {
        MessageAttachmentPayload(
            assetUrl: audioURL.absoluteString,
            custom: [
                "mime_type": .string(file.mimeType!),
                "file_size": .string("\(file.size)")
            ],
            title: title,
            type: AttachmentType.voiceRecording.rawValue
        )
    }
}
