//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageImageGallery = _ChatMessageImageGallery<NoExtraData>

open class _ChatMessageImageGallery<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    open var interItemSpacing: CGFloat = 2

    public var content: _ChatMessageAttachmentListViewData<ExtraData>? {
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
        label.font = uiConfig.font.title
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
    }()

    private var layouts: [[NSLayoutConstraint]] = []

    // MARK: - Overrides

    override open func setUpLayout() {
        previews.forEach(addSubview)
        addSubview(moreImagesOverlay)

        let anchorSpacing = interItemSpacing / 2

        layouts = [
            [
                previews[0].leadingAnchor.pin(equalTo: leadingAnchor),
                previews[0].topAnchor.pin(equalTo: topAnchor),
                previews[0].bottomAnchor.pin(equalTo: bottomAnchor),
                previews[0].trailingAnchor.pin(equalTo: trailingAnchor)
            ],
            [
                previews[0].leadingAnchor.pin(equalTo: leadingAnchor),
                previews[0].topAnchor.pin(equalTo: topAnchor),
                previews[0].bottomAnchor.pin(equalTo: bottomAnchor),
                previews[0].widthAnchor.pin(equalTo: widthAnchor, multiplier: 0.5, constant: -anchorSpacing),
                
                previews[1].trailingAnchor.pin(equalTo: trailingAnchor),
                previews[1].topAnchor.pin(equalTo: topAnchor),
                previews[1].bottomAnchor.pin(equalTo: bottomAnchor),
                previews[1].widthAnchor.pin(equalTo: previews[0].widthAnchor)
            ],
            [
                previews[0].leadingAnchor.pin(equalTo: leadingAnchor),
                previews[0].topAnchor.pin(equalTo: topAnchor),
                previews[0].bottomAnchor.pin(equalTo: bottomAnchor),
                previews[0].widthAnchor.pin(equalTo: widthAnchor, multiplier: 0.5, constant: -anchorSpacing),
                
                previews[1].topAnchor.pin(equalTo: topAnchor),
                previews[1].trailingAnchor.pin(equalTo: trailingAnchor),
                previews[1].heightAnchor.pin(equalTo: heightAnchor, multiplier: 0.5, constant: -anchorSpacing),
                previews[1].widthAnchor.pin(equalTo: previews[0].widthAnchor),
                
                previews[2].trailingAnchor.pin(equalTo: previews[1].trailingAnchor),
                previews[2].heightAnchor.pin(equalTo: previews[1].heightAnchor),
                previews[2].widthAnchor.pin(equalTo: previews[1].widthAnchor),
                previews[2].bottomAnchor.pin(equalTo: bottomAnchor)
            ],
            [
                previews[0].leadingAnchor.pin(equalTo: leadingAnchor),
                previews[0].topAnchor.pin(equalTo: topAnchor),
                previews[0].widthAnchor.pin(equalTo: widthAnchor, multiplier: 0.5, constant: -anchorSpacing),
                previews[0].heightAnchor.pin(equalTo: widthAnchor, multiplier: 0.5, constant: -anchorSpacing),
                
                previews[1].topAnchor.pin(equalTo: topAnchor),
                previews[1].trailingAnchor.pin(equalTo: trailingAnchor),
                previews[1].heightAnchor.pin(equalTo: previews[0].heightAnchor),
                previews[1].widthAnchor.pin(equalTo: previews[0].widthAnchor),
                
                previews[2].leadingAnchor.pin(equalTo: leadingAnchor),
                previews[2].heightAnchor.pin(equalTo: previews[0].heightAnchor),
                previews[2].widthAnchor.pin(equalTo: previews[0].widthAnchor),
                previews[2].bottomAnchor.pin(equalTo: bottomAnchor),
                
                previews[3].trailingAnchor.pin(equalTo: trailingAnchor),
                previews[3].heightAnchor.pin(equalTo: previews[0].heightAnchor),
                previews[3].widthAnchor.pin(equalTo: previews[0].widthAnchor),
                previews[3].bottomAnchor.pin(equalTo: bottomAnchor)
            ]
        ]

        NSLayoutConstraint.activate([
            moreImagesOverlay.leadingAnchor.pin(equalTo: previews[3].leadingAnchor),
            moreImagesOverlay.trailingAnchor.pin(equalTo: previews[3].trailingAnchor),
            moreImagesOverlay.topAnchor.pin(equalTo: previews[3].topAnchor),
            moreImagesOverlay.bottomAnchor.pin(equalTo: previews[3].bottomAnchor),
            widthAnchor.pin(equalTo: heightAnchor)
        ])
    }

    override public func defaultAppearance() {
        moreImagesOverlay.textColor = .white
        moreImagesOverlay.backgroundColor = uiConfig.colorPalette.background4
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
