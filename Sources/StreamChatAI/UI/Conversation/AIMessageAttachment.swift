//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
import UIKit
import UniformTypeIdentifiers

/// Something a message carries besides its text, such as an image or a file.
///
/// The kinds of attachment are open: a new one can appear without breaking your code.
/// ``AIMessageAttachmentView`` shows images as thumbnails and every other kind as a file, with
/// its name, type and size. Show kinds of your own, keeping what they need in `extraData`,
/// with ``AIConversationViewFactory/makeAttachmentView(options:)``.
///
/// ```swift
/// var attachments: [AIMessageAttachment] {
///     message.imageAttachments.map { .image($0.imageURL) }
///         + message.fileAttachments.map { .file($0.assetURL, name: $0.title, size: $0.file.size) }
/// }
/// ```
public struct AIMessageAttachment: Hashable, Sendable {
    /// What kind of attachment it is. It is an open set: compare against the kinds you know
    /// and give the rest a fallback.
    public struct Kind: RawRepresentable, Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { rawValue = value }
        public var description: String { rawValue }

        /// An image, shown as a thumbnail.
        public static let image: Kind = "image"
        /// A file, such as a PDF, shown with its name, type and size.
        public static let file: Kind = "file"
    }

    public var kind: Kind
    /// Where it is: on the web, or in a file on this device.
    public var url: URL?
    /// The image itself when the app holds it, such as a photo the person just took. It shows
    /// rather than the one at `url`.
    public var image: UIImage?
    /// Its name, such as the file's.
    public var name: String?
    /// Its size, in bytes.
    public var size: Int64?
    /// Its media type, such as `application/pdf`. Without it, the type comes from the
    /// extension of its name or URL.
    public var mimeType: String?
    /// Data of its own, such as what an attachment of a kind of your own needs.
    public var extraData: [String: RawJSON]

    public init(
        kind: Kind,
        url: URL? = nil,
        image: UIImage? = nil,
        name: String? = nil,
        size: Int64? = nil,
        mimeType: String? = nil,
        extraData: [String: RawJSON] = [:]
    ) {
        self.kind = kind
        self.url = url
        self.image = image
        self.name = name
        self.size = size
        self.mimeType = mimeType
        self.extraData = extraData
    }

    /// An attachment of the file at `url`, of the kind its type says: an image for an image
    /// file, and a file otherwise. Such as for the files the person picked in the composer.
    public init(url: URL, name: String? = nil, size: Int64? = nil, mimeType: String? = nil) {
        self.init(kind: .file, url: url, name: name, size: size, mimeType: mimeType)
        if let type = contentType, type.conforms(to: .image), !type.conforms(to: .svg) {
            kind = .image
        }
    }

    /// An image to load, from the web or a file.
    public static func image(_ url: URL, name: String? = nil) -> Self {
        Self(kind: .image, url: url, name: name)
    }

    /// An image the app holds, such as a photo the person just took.
    public static func image(_ image: UIImage, name: String? = nil) -> Self {
        Self(kind: .image, image: image, name: name)
    }

    /// A file to open, from the web or this device.
    public static func file(_ url: URL, name: String? = nil, size: Int64? = nil, mimeType: String? = nil) -> Self {
        Self(kind: .file, url: url, name: name, size: size, mimeType: mimeType)
    }
}

extension AIMessageAttachment {
    // The type of its content, from its media type or else its extension.
    var contentType: UTType? {
        if let mimeType, let type = UTType(mimeType: mimeType) {
            return type
        }
        return pathExtension.flatMap { UTType(filenameExtension: $0) }
    }

    private var pathExtension: String? {
        [name, url?.lastPathComponent]
            .compactMap { $0 }
            .map { ($0 as NSString).pathExtension }
            .first { !$0.isEmpty }
    }

    var displayName: String {
        if let name, !name.isEmpty {
            return name
        }
        if let file = url?.lastPathComponent, !file.isEmpty, file != "/" {
            return file
        }
        return kind == .image ? L10n.Attachment.image : L10n.Attachment.file
    }

    // Its type and size, such as "PDF · 2.4 MB".
    var details: String {
        let type = (pathExtension ?? contentType?.preferredFilenameExtension)?.uppercased()
        let formattedSize = size.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
        switch (type, formattedSize) {
        case let (type?, size?):
            return L10n.Attachment.details(type, size)
        case let (type?, nil):
            return type
        case let (nil, size?):
            return size
        case (nil, nil):
            return ""
        }
    }
}
