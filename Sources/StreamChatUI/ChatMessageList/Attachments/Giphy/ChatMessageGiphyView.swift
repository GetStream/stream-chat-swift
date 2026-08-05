//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageGiphyView: _View, ComponentsProvider {
    public var content: ChatMessageGiphyAttachment? {
        didSet {
            let isDifferentImage = oldValue?.previewURL != content?.previewURL
            guard hasFailed || isDifferentImage else { return }
            updateContentIfNeeded()
        }
    }

    private var imageTask: ImageLoadingTask? {
        didSet { oldValue?.cancel() }
    }

    public private(set) lazy var imageView = StreamAnimatedImageView()
        .withoutAutoresizingMaskConstraints
        .withAccessibilityIdentifier(identifier: "imageView")

    public private(set) lazy var badge = components
        .giphyBadgeView
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var loadingIndicator = components
        .loadingIndicator
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) var hasFailed = false

    deinit {
        imageTask?.cancel()
    }

    override open func setUpLayout() {
        super.setUpLayout()

        widthAnchor.pin(equalTo: heightAnchor).isActive = true

        embed(imageView)

        addSubview(loadingIndicator)
        loadingIndicator.pin(anchors: [.centerX, .centerY], to: imageView)

        addSubview(badge)
        badge.pin(anchors: [.leading, .bottom], to: layoutMarginsGuide)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
    }

    override open func updateContent() {
        super.updateContent()

        guard let url = content?.previewURL else { return }

        imageView.stopAnimating()
        loadingIndicator.isHidden = false

        let task = ImageLoadingTask()
        imageTask = task
        components.mediaLoader.loadImage(url: url, options: ImageLoadOptions()) { [weak self] result in
            guard let self, !task.isCancelled else { return }
            loadingIndicator.isHidden = true
            switch result {
            case let .success(loadedImage):
                if let animatedImageData = loadedImage.animatedImageData {
                    imageView.setAnimatedImage(data: animatedImageData, fallbackImage: loadedImage.image)
                } else {
                    imageView.clearAnimatedImage()
                    imageView.image = loadedImage.image
                }
                hasFailed = false
            case .failure:
                hasFailed = true
            }
        }
    }
}
