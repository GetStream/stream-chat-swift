//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageAttachmentsView = _ChatMessageAttachmentsView<NoExtraData>

open class _ChatMessageAttachmentsView<ExtraData: ExtraDataTypes>: _View, ComponentsProvider, SwiftUIRepresentable {
    /// All attachments with `type == .image` will be shown in a gallery
    /// All the other ones will be treated as files.
    public var content: _ChatMessageAttachmentListViewData<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var imageGallery = components
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .imageGallery
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var fileList = components
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .fileAttachmentListView
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var interactiveAttachmentView = components
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .interactiveAttachmentView
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var giphyView = components
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .giphyAttachmentView
        .init()
        .withoutAutoresizingMaskConstraints

    private var layoutConstraints: [LayoutOptions: [NSLayoutConstraint]] = [:]

    // MARK: - Overrides

    override open func setUpLayout() {
        addSubview(imageGallery)
        addSubview(fileList)
        addSubview(giphyView)
        addSubview(interactiveAttachmentView)

        layoutConstraints[.images] = [
            imageGallery.leadingAnchor.pin(equalTo: leadingAnchor),
            imageGallery.trailingAnchor.pin(equalTo: trailingAnchor),
            imageGallery.topAnchor.pin(equalTo: topAnchor),
            imageGallery.bottomAnchor.pin(equalTo: bottomAnchor)
        ]

        layoutConstraints[.files] = [
            fileList.leadingAnchor.pin(equalTo: leadingAnchor),
            fileList.trailingAnchor.pin(equalTo: trailingAnchor),
            fileList.topAnchor.pin(equalTo: topAnchor),
            fileList.bottomAnchor.pin(equalTo: bottomAnchor)
        ]

        layoutConstraints[.giphy] = [
            giphyView.leadingAnchor.pin(equalTo: leadingAnchor),
            giphyView.trailingAnchor.pin(equalTo: trailingAnchor),
            giphyView.topAnchor.pin(equalTo: topAnchor),
            giphyView.bottomAnchor.pin(equalTo: bottomAnchor)
        ]

        layoutConstraints[.interactiveAttachment] = [
            interactiveAttachmentView.leadingAnchor.pin(equalTo: leadingAnchor),
            interactiveAttachmentView.trailingAnchor.pin(equalTo: trailingAnchor),
            interactiveAttachmentView.topAnchor.pin(equalTo: topAnchor),
            interactiveAttachmentView.bottomAnchor.pin(equalTo: bottomAnchor)
        ]
        layoutConstraints[[.images, .interactiveAttachment]] = layoutConstraints[.interactiveAttachment]
        layoutConstraints[[.files, .interactiveAttachment]] = layoutConstraints[.interactiveAttachment]
        layoutConstraints[[.giphy, .interactiveAttachment]] = layoutConstraints[.interactiveAttachment]
        layoutConstraints[.all] = layoutConstraints[.interactiveAttachment]

        layoutConstraints[[.images, .files]] = [
            imageGallery.leadingAnchor.pin(equalTo: leadingAnchor),
            imageGallery.trailingAnchor.pin(equalTo: trailingAnchor),
            imageGallery.topAnchor.pin(equalTo: topAnchor),
            
            fileList.leadingAnchor.pin(equalTo: leadingAnchor),
            fileList.trailingAnchor.pin(equalTo: trailingAnchor),
            fileList.topAnchor.pin(equalTo: imageGallery.bottomAnchor),
            fileList.bottomAnchor.pin(equalTo: bottomAnchor)
        ]
    }

    override open func updateContent() {
        let layoutOptions = calculateLayoutOptions()

        imageGallery.content = content.map {
            .init(
                attachments: $0.attachments.filter { $0.type == .image },
                didTapOnAttachment: $0.didTapOnAttachment,
                didTapOnAttachmentAction: nil
            )
        }
        imageGallery.isVisible = layoutOptions.contains(.images)

        fileList.content = content.map {
            .init(
                attachments: $0.attachments.filter { $0.type == .file },
                didTapOnAttachment: $0.didTapOnAttachment,
                didTapOnAttachmentAction: nil
            )
        }
        fileList.isVisible = layoutOptions.contains(.files)

        giphyView.content = content?.attachments.first { $0.type == .giphy }
        giphyView.isVisible = layoutOptions.contains(.giphy)

        interactiveAttachmentView.content = content?.items.first {
            !$0.attachment.actions.isEmpty
        }
        interactiveAttachmentView.isVisible = layoutOptions.contains(.interactiveAttachment)

        layoutConstraints.values.flatMap { $0 }.forEach { $0.isActive = false }
        layoutConstraints[layoutOptions]?.forEach { $0.isActive = true }
    }

    // MARK: - Private

    private func calculateLayoutOptions() -> LayoutOptions {
        var options: LayoutOptions = []

        for attachment in content?.attachments ?? [] {
            if !attachment.actions.isEmpty {
                options.insert(.interactiveAttachment)
            } else if attachment.type == .image {
                options.insert(.images)
            } else if attachment.type == .giphy {
                options.insert(.giphy)
            } else {
                options.insert(.files)
            }
        }

        // If there is an interactive attachment it should be the only content we display.
        return options.contains(.interactiveAttachment) ? .interactiveAttachment : options
    }
}

// MARK: - LayoutOptions

private struct LayoutOptions: OptionSet, Hashable {
    let rawValue: Int

    static let images = Self(rawValue: 1 << 0)
    static let files = Self(rawValue: 1 << 1)
    static let interactiveAttachment = Self(rawValue: 1 << 2)
    static let giphy = Self(rawValue: 1 << 3)

    static let all: Self = [.images, .files, .interactiveAttachment, .giphy]
}
