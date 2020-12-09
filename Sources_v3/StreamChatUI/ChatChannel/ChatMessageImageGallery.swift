//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

open class ChatMessageImageGallery<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var data: Data? {
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

        let anchorSpacing = -uiConfig.messageList.messageContentSubviews.imageGalleryInteritemSpacing / 2

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

    override open func defaultAppearance() {
        moreImagesOverlay.textColor = .white
        moreImagesOverlay.backgroundColor = uiConfig.colorPalette.galleryMoreImagesOverlayBackground
    }

    override open func updateContent() {
        for (index, itemPreview) in previews.enumerated() {
            let attachment = data?.attachments[safe: index]

            itemPreview.isHidden = attachment == nil
            itemPreview.previewURL = attachment?.imagePreviewURL ?? attachment?.imageURL
            itemPreview.didTap = attachment.flatMap { image in
                { [weak self] in
                    self?.data?.didTapOnAttachment?(image)
                }
            }
        }

        let visiblePreviewsCount = previews.filter { !$0.isHidden }.count
        layouts.flatMap { $0 }.forEach { $0.isActive = false }
        layouts[max(visiblePreviewsCount - 1, 0)].forEach { $0.isActive = true }

        let otherImagesCount = (data?.attachments.count ?? 0) - previews.count
        moreImagesOverlay.isHidden = otherImagesCount <= 0
        moreImagesOverlay.text = "+\(otherImagesCount)"
    }

    // MARK: - Private

    private func createImagePreview() -> ImagePreview {
        uiConfig
            .messageList
            .messageContentSubviews
            .imageGalleryItem
            .init()
            .withoutAutoresizingMaskConstraints
    }
}

// MARK: - Data

extension ChatMessageImageGallery {
    public struct Data {
        public let attachments: [_ChatMessageAttachment<ExtraData>]
        public let didTapOnAttachment: ((_ChatMessageAttachment<ExtraData>) -> Void)?

        public init(
            attachments: [_ChatMessageAttachment<ExtraData>],
            didTapOnAttachment: ((_ChatMessageAttachment<ExtraData>) -> Void)?
        ) {
            self.attachments = attachments
            self.didTapOnAttachment = didTapOnAttachment
        }
    }
}

// MARK: - ImagePreview

extension ChatMessageImageGallery {
    open class ImagePreview: View {
        public var previewURL: URL? {
            didSet { updateContentIfNeeded() }
        }

        public var didTap: (() -> Void)?

        private var imageTask: ImageTask? {
            didSet { oldValue?.cancel() }
        }

        // MARK: - Subviews

        public private(set) lazy var imageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
            return imageView.withoutAutoresizingMaskConstraints
        }()

        public private(set) lazy var activityIndicator: UIActivityIndicatorView = {
            let indicator = UIActivityIndicatorView()
            indicator.hidesWhenStopped = true
            indicator.style = .gray
            return indicator.withoutAutoresizingMaskConstraints
        }()

        // MARK: - Overrides

        override open func setUp() {
            super.setUp()
            
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler(_:)))
            addGestureRecognizer(tapRecognizer)
        }

        override open func setUpLayout() {
            embed(imageView)
            embed(activityIndicator)
        }

        override open func updateContent() {
            if let url = previewURL {
                activityIndicator.startAnimating()
                imageTask = loadImage(with: url, options: .shared, into: imageView, completion: { [weak self] _ in
                    self?.activityIndicator.stopAnimating()
                    self?.imageTask = nil
                })
            } else {
                activityIndicator.stopAnimating()
                imageView.image = nil
                imageTask = nil
            }
        }

        // MARK: - Actions

        @objc open func tapHandler(_ recognizer: UITapGestureRecognizer) {
            didTap?()
        }

        // MARK: - Init & Deinit

        deinit {
            imageTask?.cancel()
        }
    }
}
