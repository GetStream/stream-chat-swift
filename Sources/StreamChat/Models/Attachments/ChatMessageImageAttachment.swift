//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type alias for attachment with `ImageAttachmentPayload` payload type.
///
/// The `ChatMessageImageAttachment` attachment will be added to the message automatically
/// if the message was sent with attached `AnyAttachmentPayload` created with
/// local URL and `.image` attachment type.
public typealias ChatMessageImageAttachment = ChatMessageAttachment<ImageAttachmentPayload>

/// Represents a payload for attachments with `.image` type.
public struct ImageAttachmentPayload: AttachmentPayload {
    /// An attachment type all `ImageAttachmentPayload` instances conform to. Is set to `.image`.
    public static let type: AttachmentType = .image

    /// A title, usually the name of the image.
    public var title: String?
    /// A link to the image.
    public var imageURL: URL
    /// A link to the image preview.
    public var imagePreviewURL: URL
    /// Attachment actions.
    public var actions: [AttachmentAction]
    /// An extra data.
    public var extraData: [String: RawJSON]?
    
    /// Decodes extra data as an instance of the given type.
    /// - Parameter ofType: The type an extra data should be decoded as.
    /// - Returns: Extra data of the given type or `nil` if decoding fails.
    public func extraData<T: Decodable>(ofType: T.Type = T.self) -> T? {
        extraData
            .flatMap { try? JSONEncoder.stream.encode($0) }
            .flatMap { try? JSONDecoder.stream.decode(T.self, from: $0) }
    }
    
    /// Creates `ImageAttachmentPayload` instance.
    ///
    /// Use this initializer if the attachment is already uploaded and you have the remote URLs.
    public init(
        title: String?,
        imageRemoteURL: URL,
        imagePreviewRemoteURL: URL? = nil,
        actions: [AttachmentAction] = [],
        extraData: [String: RawJSON]? = nil
    ) {
        self.title = title
        imageURL = imageRemoteURL
        imagePreviewURL = imagePreviewRemoteURL ?? imageRemoteURL
        self.actions = actions
        self.extraData = extraData
    }
}

extension ImageAttachmentPayload: Hashable {}

// MARK: - Encodable

extension ImageAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        let actionsData = try JSONEncoder.default.encode(actions)
        let actions = try JSONDecoder.default.decode([RawJSON].self, from: actionsData)
        
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.title.rawValue] = title.map { .string($0) }
        values[AttachmentCodingKeys.imageURL.rawValue] = .string(imageURL.absoluteString)
        values[AttachmentCodingKeys.actions.rawValue] = .array(actions)
        try values.encode(to: encoder)
    }
}

// MARK: - Decodable

extension ImageAttachmentPayload: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AttachmentCodingKeys.self)
        
        let imageURL = try
            container.decodeIfPresent(URL.self, forKey: .image) ??
            container.decodeIfPresent(URL.self, forKey: .imageURL) ??
            container.decode(URL.self, forKey: .assetURL)
        
        let title = (
            try container.decodeIfPresent(String.self, forKey: .title) ??
                container.decodeIfPresent(String.self, forKey: .fallback) ??
                container.decodeIfPresent(String.self, forKey: .name)
        )?.trimmingCharacters(in: .whitespacesAndNewlines)

        self.init(
            title: title,
            imageRemoteURL: imageURL,
            imagePreviewRemoteURL: try container
                .decodeIfPresent(URL.self, forKey: .thumbURL) ?? imageURL,
            actions: try container
                .decodeIfPresent([AttachmentAction].self, forKey: .actions) ?? [],
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
