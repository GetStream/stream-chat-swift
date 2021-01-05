//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageImageGallery<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var content: AttachmentListViewData<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var previews = [
        createImagePreview(),
        createImagePreview(),
        createImagePreview(),
        createImagePreview()
    ]

    public private(set) lazy var moreImagesOverlay: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle).bold
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label.withoutAutoresizingMaskConstraints
    }()

    private var layouts: [[NSLayoutConstraint]] = []

    // MARK: - Overrides

    override open func setUpLayout() {
        previews.forEach(addSubview)
        addSubview(moreImagesOverlay)

        let anchorSpacing = -uiConfig.messageList.messageContentSubviews.attachmentSubviews.imageGalleryInteritemSpacing / 2

        layouts = [
            [
                previews[0].leadingAnchor.constraint(equalTo: leadingAnchor),
                previews[0].topAnchor.constraint(equalTo: topAnchor),
                previews[0].bottomAnchor.constraint(equalTo: bottomAnchor),
                previews[0].trailingAnchor.constraint(equalTo: trailingAnchor)
            ],
            [
                previews[0].leadingAnchor.constraint(equalTo: leadingAnchor),
                previews[0].topAnchor.constraint(equalTo: topAnchor),
                previews[0].bottomAnchor.constraint(equalTo: bottomAnchor),
                previews[0].widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: anchorSpacing),
                
                previews[1].trailingAnchor.constraint(equalTo: trailingAnchor),
                previews[1].topAnchor.constraint(equalTo: topAnchor),
                previews[1].bottomAnchor.constraint(equalTo: bottomAnchor),
                previews[1].widthAnchor.constraint(equalTo: previews[0].widthAnchor)
            ],
            [
                previews[0].leadingAnchor.constraint(equalTo: leadingAnchor),
                previews[0].topAnchor.constraint(equalTo: topAnchor),
                previews[0].bottomAnchor.constraint(equalTo: bottomAnchor),
                previews[0].widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: anchorSpacing),
                
                previews[1].topAnchor.constraint(equalTo: topAnchor),
                previews[1].trailingAnchor.constraint(equalTo: trailingAnchor),
                previews[1].heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5, constant: anchorSpacing),
                previews[1].widthAnchor.constraint(equalTo: previews[0].widthAnchor),
                
                previews[2].trailingAnchor.constraint(equalTo: previews[1].trailingAnchor),
                previews[2].heightAnchor.constraint(equalTo: previews[1].heightAnchor),
                previews[2].widthAnchor.constraint(equalTo: previews[1].widthAnchor),
                previews[2].bottomAnchor.constraint(equalTo: bottomAnchor)
            ],
            [
                previews[0].leadingAnchor.constraint(equalTo: leadingAnchor),
                previews[0].topAnchor.constraint(equalTo: topAnchor),
                previews[0].widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: anchorSpacing),
                previews[0].heightAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: anchorSpacing),
                
                previews[1].topAnchor.constraint(equalTo: topAnchor),
                previews[1].trailingAnchor.constraint(equalTo: trailingAnchor),
                previews[1].heightAnchor.constraint(equalTo: previews[0].heightAnchor),
                previews[1].widthAnchor.constraint(equalTo: previews[0].widthAnchor),
                
                previews[2].leadingAnchor.constraint(equalTo: leadingAnchor),
                previews[2].heightAnchor.constraint(equalTo: previews[0].heightAnchor),
                previews[2].widthAnchor.constraint(equalTo: previews[0].widthAnchor),
                previews[2].bottomAnchor.constraint(equalTo: bottomAnchor),
                
                previews[3].trailingAnchor.constraint(equalTo: trailingAnchor),
                previews[3].heightAnchor.constraint(equalTo: previews[0].heightAnchor),
                previews[3].widthAnchor.constraint(equalTo: previews[0].widthAnchor),
                previews[3].bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        ]

        NSLayoutConstraint.activate([
            moreImagesOverlay.leadingAnchor.constraint(equalTo: previews[3].leadingAnchor),
            moreImagesOverlay.trailingAnchor.constraint(equalTo: previews[3].trailingAnchor),
            moreImagesOverlay.topAnchor.constraint(equalTo: previews[3].topAnchor),
            moreImagesOverlay.bottomAnchor.constraint(equalTo: previews[3].bottomAnchor),
            widthAnchor.constraint(equalTo: heightAnchor)
        ])
    }

    override public func defaultAppearance() {
        moreImagesOverlay.textColor = .white
        moreImagesOverlay.backgroundColor = uiConfig.colorPalette.galleryMoreImagesOverlayBackground
    }

    override open func updateContent() {
        let items = content?.items
        for (index, itemPreview) in previews.enumerated() {
            itemPreview.content = items?[safe: index]
            itemPreview.isHidden = itemPreview.content == nil
        }

        let visiblePreviewsCount = previews.filter { !$0.isHidden }.count
        layouts.flatMap { $0 }.forEach { $0.isActive = false }
        layouts[max(visiblePreviewsCount - 1, 0)].forEach { $0.isActive = true }

        let otherImagesCount = (content?.attachments.count ?? 0) - previews.count
        moreImagesOverlay.isHidden = otherImagesCount <= 0
        moreImagesOverlay.text = "+\(otherImagesCount)"
    }

    // MARK: - Private

    private func createImagePreview() -> ImagePreview {
        uiConfig
            .messageList
            .messageContentSubviews
            .attachmentSubviews
            .imageGalleryItem
            .init()
            .withoutAutoresizingMaskConstraints
    }
}
