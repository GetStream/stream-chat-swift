//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageAttachmentsView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    /// All attachments with `type == .image` will be shown in a gallery
    /// All the other ones will be treated as files.
    public var content: AttachmentListViewData<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var imageGallery = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .imageGallery
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var fileList = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .fileAttachmentListView
        .init()
        .withoutAutoresizingMaskConstraints

    private var layoutConstraints: [LayoutOptions: [NSLayoutConstraint]] = [:]

    // MARK: - Overrides

    override open func setUpLayout() {
        addSubview(imageGallery)
        addSubview(fileList)

        layoutConstraints[.images] = [
            imageGallery.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageGallery.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageGallery.topAnchor.constraint(equalTo: topAnchor),
            imageGallery.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        layoutConstraints[.files] = [
            fileList.leadingAnchor.constraint(equalTo: leadingAnchor),
            fileList.trailingAnchor.constraint(equalTo: trailingAnchor),
            fileList.topAnchor.constraint(equalTo: topAnchor),
            fileList.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        layoutConstraints[[.images, .files]] = [
            imageGallery.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageGallery.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageGallery.topAnchor.constraint(equalTo: topAnchor),
            
            fileList.leadingAnchor.constraint(equalTo: leadingAnchor),
            fileList.trailingAnchor.constraint(equalTo: trailingAnchor),
            fileList.topAnchor.constraint(equalTo: imageGallery.bottomAnchor),
            fileList.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
    }

    override open func updateContent() {
        let layoutOptions = calculateLayoutOptions()

        imageGallery.content = content.flatMap {
            .init(
                attachments: $0.attachments.filter { $0.type == .image },
                didTapOnAttachment: $0.didTapOnAttachment
            )
        }
        imageGallery.isVisible = layoutOptions.contains(.images)

        fileList.content = content.flatMap {
            .init(
                attachments: $0.attachments.filter { $0.type == .file },
                didTapOnAttachment: $0.didTapOnAttachment
            )
        }
        fileList.isVisible = layoutOptions.contains(.files)

        layoutConstraints.values.flatMap { $0 }.forEach { $0.isActive = false }
        layoutConstraints[layoutOptions]?.forEach { $0.isActive = true }
    }

    // MARK: - Private

    private func calculateLayoutOptions() -> LayoutOptions {
        var options: LayoutOptions = []

        for attachment in content?.attachments ?? [] {
            options.insert(attachment.type == .image ? .images : .files)
        }

        return options
    }
}

// MARK: - LayoutOptions

private struct LayoutOptions: OptionSet, Hashable {
    let rawValue: Int

    static let images = Self(rawValue: 1 << 0)
    static let files = Self(rawValue: 1 << 1)

    static let all: Self = [.images, .files]
}
