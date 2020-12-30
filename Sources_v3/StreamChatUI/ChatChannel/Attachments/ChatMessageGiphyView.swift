//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import SwiftyGif
import UIKit

open class ChatMessageGiphyView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
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

        widthAnchor.constraint(equalTo: heightAnchor).isActive = true

        embed(imageView)

        addSubview(loadingIndicator)
        loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }

    override open func defaultAppearance() {
        super.defaultAppearance()
        backgroundColor = .clear
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
