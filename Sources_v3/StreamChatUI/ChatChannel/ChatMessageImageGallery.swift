//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

open class ChatMessageImageGallery<ExtraData: UIExtraDataTypes>: View, UIConfigProvider {
    public var didTapOnAttachment: ((_ChatMessageAttachment<ExtraData>) -> Void)? {
        didSet { updateContentIfNeeded() }
    }

    public var imageAttachments: [_ChatMessageAttachment<ExtraData>] = [] {
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
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle).bold()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var leftVStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 2
        return stack.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var rightVStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 2
        return stack.withoutAutoresizingMaskConstraints
    }()

    public private(set) lazy var rootHStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 2
        return stack.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override open func setUpLayout() {
        leftVStack.addArrangedSubview(previews[0])
        rightVStack.addArrangedSubview(previews[1])
        leftVStack.addArrangedSubview(previews[2])
        rightVStack.addArrangedSubview(previews[3])

        rootHStack.addArrangedSubview(leftVStack)
        rootHStack.addArrangedSubview(rightVStack)

        embed(rootHStack)

        previews[3].embed(moreImagesOverlay)

        widthAnchor.constraint(equalTo: heightAnchor).isActive = true
    }

    override open func defaultAppearance() {
        moreImagesOverlay.textColor = .white
        moreImagesOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }

    override open func updateContent() {
        for (index, itemPreview) in previews.enumerated() {
            let attachment = imageAttachments[safe: index]

            itemPreview.isHidden = attachment == nil
            itemPreview.previewURL = attachment?.imagePreviewURL ?? attachment?.imageURL
            itemPreview.didTap = attachment.flatMap { image in
                { [weak self] in
                    self?.didTapOnAttachment?(image)
                }
            }
        }

        for stack in [leftVStack, rightVStack, rootHStack] {
            stack.isHidden = stack.arrangedSubviews.allSatisfy { $0.isHidden }
        }
        
        let otherImagesCount = imageAttachments.count - previews.count
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
