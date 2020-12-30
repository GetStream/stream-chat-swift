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

    public private(set) lazy var interactiveAttachmentView = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .interactiveAttachmentView
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var giphyView = uiConfig
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

        layoutConstraints[.giphy] = [
            giphyView.leadingAnchor.constraint(equalTo: leadingAnchor),
            giphyView.trailingAnchor.constraint(equalTo: trailingAnchor),
            giphyView.topAnchor.constraint(equalTo: topAnchor),
            giphyView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]

        layoutConstraints[.interactiveAttachment] = [
            interactiveAttachmentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            interactiveAttachmentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            interactiveAttachmentView.topAnchor.constraint(equalTo: topAnchor),
            interactiveAttachmentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        layoutConstraints[[.images, .interactiveAttachment]] = layoutConstraints[.interactiveAttachment]
        layoutConstraints[[.files, .interactiveAttachment]] = layoutConstraints[.interactiveAttachment]
        layoutConstraints[[.giphy, .interactiveAttachment]] = layoutConstraints[.interactiveAttachment]
        layoutConstraints[.all] = layoutConstraints[.interactiveAttachment]

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
