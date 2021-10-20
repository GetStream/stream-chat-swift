//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

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
    
    private var dataTask: URLSessionDataTask? {
        didSet { oldValue?.cancel() }
    }

    private var gifLoadingHandler = SwiftyGifLoadingHandler()

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
        dataTask?.cancel()
    }

    override open func setUp() {
        super.setUp()

        gifLoadingHandler.didFail = { [weak self] _ in
            self?.hasFailed = true
        }

        gifLoadingHandler.didSucceed = { [weak self] in
            self?.hasFailed = false
        }

        imageView.delegate = gifLoadingHandler
    }

    override open func setUpLayout() {
        super.setUpLayout()

        widthAnchor.pin(equalTo: heightAnchor).isActive = true

        embed(imageView)

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

        if let url = content?.previewURL {
            dataTask = imageView.setGifFromURL(url, customLoader: loadingIndicator)
        }
    }
}

// Internal class to handle the SwiftyGifDelegate.
// Right now exposing the SwiftyGifDelegate breaks the SDK.
extension ChatMessageGiphyView {
    class SwiftyGifLoadingHandler: SwiftyGifDelegate {
        var didFail: (Error?) -> Void = { _ in }
        var didSucceed: () -> Void = {}

        func gifDidStart(sender: UIImageView) {
            didSucceed()
        }

        func gifURLDidFail(sender: UIImageView, url: URL, error: Error?) {
            didFail(error)
        }
    }
}
