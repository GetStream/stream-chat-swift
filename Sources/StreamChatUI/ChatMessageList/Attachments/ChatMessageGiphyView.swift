//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import SwiftyGif
import UIKit

public typealias ChatMessageGiphyView = _ChatMessageGiphyView<NoExtraData>

open class _ChatMessageGiphyView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public var content: _ChatMessageAttachment<ExtraData>? {
        didSet {
            let isDifferentImage = oldValue?.imageURL != content?.imageURL
            guard hasFailed || isDifferentImage else { return }
            updateContentIfNeeded()
        }
    }

    private var imageTask: ImageTask? {
        didSet { oldValue?.cancel() }
    }

    public private(set) lazy var imageView = UIImageView().withoutAutoresizingMaskConstraints

    public private(set) lazy var badge = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .giphyBadgeView
        .init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var loadingIndicator = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
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

    override public func defaultAppearance() {
        super.defaultAppearance()
        backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
    }

    override open func updateContent() {
        super.updateContent()

        hasFailed = false
        loadingIndicator.isVisible = true
        imageTask = nil
        imageView.clear()

        if let url = content?.imageURL {
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

extension _ChatMessageGiphyView {
    open class GiphyBadge: View, UIConfigProvider {
        public private(set) lazy var title: UILabel = {
            let label = UILabel().withoutAutoresizingMaskConstraints
            label.text = "GIPHY"
            label.textColor = uiConfig.colorPalette.giphyBadgeText
            label.font = uiConfig.font.bodyBold
            return label
        }()

        public private(set) lazy var lightning = UIImageView(
            image: uiConfig
                .messageList
                .messageContentSubviews
                .attachmentSubviews
                .giphyBadgeIcon
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

        override public func defaultAppearance() {
            super.defaultAppearance()

            backgroundColor = UIColor.black.withAlphaComponent(0.6)
            lightning.tintColor = uiConfig.colorPalette.giphyBadgeText
        }

        override open func layoutSubviews() {
            super.layoutSubviews()

            layer.cornerRadius = bounds.height / 2
        }
    }
}
