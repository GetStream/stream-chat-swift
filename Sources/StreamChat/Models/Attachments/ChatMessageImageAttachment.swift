//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    /// The original width of the image in pixels.
    public var originalWidth: Double?
    /// The original height of the image in pixels.
    public var originalHeight: Double?
    /// The image file size information.
    public var file: AttachmentFile
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
    /// Use this initializer if the attachment is already uploaded and you have the remote URLs. Create the ``AttachmentFile`` type using the local file URL.
    ///
    /// - Parameters:
    ///   - title: A title, usually the name of the image.
    ///   - imageRemoteURL: A link to the image.
    ///   - file: The image file size information.
    ///   - originalWidth: The original width of the image in pixels.
    ///   - originalHeight: The original height of the image in pixels.
    ///   - extraData: Custom data associated with the attachment.
    public init(
        title: String?,
        imageRemoteURL: URL,
        file: AttachmentFile,
        originalWidth: Double? = nil,
        originalHeight: Double? = nil,
        extraData: [String: RawJSON]? = nil
    ) {
        self.title = title
        imageURL = imageRemoteURL
        self.file = file
        self.originalWidth = originalWidth
        self.originalHeight = originalHeight
        self.extraData = extraData
    }
}

extension ImageAttachmentPayload: Hashable {}

// MARK: - Local Downloads

extension ImageAttachmentPayload: AttachmentPayloadDownloading {
    public var localStorageFileName: String {
        title ?? imageURL.lastPathComponent
    }
    
    public var remoteURL: URL {
        imageURL
    }
}

// MARK: - Encodable

extension ImageAttachmentPayload: Encodable {
    public func encode(to encoder: Encoder) throws {
        var values = extraData ?? [:]
        values[AttachmentCodingKeys.title.rawValue] = title.map { .string($0) }
        values[AttachmentCodingKeys.imageURL.rawValue] = .string(imageURL.absoluteString)

        if let originalWidth = self.originalWidth, let originalHeight = self.originalHeight {
            values[AttachmentCodingKeys.originalWidth.rawValue] = .double(originalWidth)
            values[AttachmentCodingKeys.originalHeight.rawValue] = .double(originalHeight)
        }
        
        if file.size > 0 {
            values[AttachmentFile.CodingKeys.size.rawValue] = .number(Double(Int(file.size)))
            values[AttachmentFile.CodingKeys.mimeType.rawValue] = file.mimeType.map { .string($0) }
        }

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

        let title: String? = try {
            if let title = try container.decodeIfPresent(String.self, forKey: .title) {
                return title
            }
            if let fallback = try container.decodeIfPresent(String.self, forKey: .fallback) {
                return fallback
            }
            return try container.decodeIfPresent(String.self, forKey: .name)
        }()
        
        let file = try AttachmentFile(from: decoder)
        let originalWidth = try container.decodeIfPresent(Double.self, forKey: .originalWidth)
        let originalHeight = try container.decodeIfPresent(Double.self, forKey: .originalHeight)

        self.init(
            title: title?.trimmingCharacters(in: .whitespacesAndNewlines),
            imageRemoteURL: imageURL,
            file: file,
            originalWidth: originalWidth,
            originalHeight: originalHeight,
            extraData: try Self.decodeExtraData(from: decoder)
        )
    }
}
