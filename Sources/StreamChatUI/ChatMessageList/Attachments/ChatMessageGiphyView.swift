//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import SwiftyGif
import UIKit

open class ChatMessageGiphyView: _View, ComponentsProvider {
    public var content: ChatMessageGiphyAttachment? {
        didSet {
            let isDifferentImage = oldValue?.previewURL != content?.previewURL
            guard hasFailed || isDifferentImage else { return }
            updateContentIfNeeded()
        }
    }
    
    private var imageTask: ImageTask? {
        didSet { oldValue?.cancel() }
    }

    public private(set) lazy var imageView = UIImageView().withoutAutoresizingMaskConstraints

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

        addSubview(badge)
        badge.pin(anchors: [.leading, .bottom], to: layoutMarginsGuide)

        addSubview(loadingIndicator)
        loadingIndicator.centerYAnchor.pin(equalTo: centerYAnchor).isActive = true
        loadingIndicator.centerXAnchor.pin(equalTo: centerXAnchor).isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
    }

    override open func updateContent() {
        super.updateContent()

        hasFailed = false
        loadingIndicator.isVisible = true
        imageTask = nil
        imageView.clear()

        if let url = content?.previewURL {
            imageTask = ImagePipeline.shared.loadData(with: url) { [weak self] result in
                guard case let .success((rawGif, _)) = result else {
                    self?.hasFailed = true
                    return
                }
                guard let image = try? UIImage(gifData: rawGif) else { return }
                self?.imageView.setGifImage(image)
                self?.loadingIndicator.isVisible = false
                self?.imageTask = nil
            }
        }
    }
}

extension ChatMessageGiphyView {
    open class GiphyBadge: _View, AppearanceProvider {
        public private(set) lazy var title: UILabel = {
            let label = UILabel().withoutAutoresizingMaskConstraints
            label.text = "GIPHY"
            label.textColor = appearance.colorPalette.staticColorText
            label.font = appearance.fonts.bodyBold
            return label.withBidirectionalLanguagesSupport
        }()

        public private(set) lazy var lightning = UIImageView(
            image: appearance
                .images
                .commandGiphy
        )
        public private(set) lazy var contentStack: UIStackView = {
            let stack = UIStackView(arrangedSubviews: [lightning, title]).withoutAutoresizingMaskConstraints
            stack.axis = .horizontal
            stack.alignment = .center
            return stack
        }()

        override open func setUpLayout() {
            super.setUpLayout()

            directionalLayoutMargins = NSDirectionalEdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)

            addSubview(contentStack)
            contentStack.pin(to: layoutMarginsGuide)
        }

        override open func setUpAppearance() {
            super.setUpAppearance()
            backgroundColor = UIColor.black.withAlphaComponent(0.6)
            lightning.tintColor = appearance.colorPalette.staticColorText
        }

        override open func layoutSubviews() {
            super.layoutSubviews()

            layer.cornerRadius = bounds.height / 2
        }
    }
}
