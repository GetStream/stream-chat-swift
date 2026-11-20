//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// `UICollectionViewCell` for video gallery item.
open class VideoAttachmentGalleryCell: GalleryCollectionViewCell {
    /// A cell reuse identifier.
    open class var reuseId: String { String(describing: self) }

    /// A player that handles the video content.
    public var player: AVPlayer {
        playerView.player
    }

    private(set) var currentAssetLoadingError: Error?
    var onAssetLoadingErrorChange: ((Error?) -> Void)?

    private var loadedAttachmentID: AttachmentId?
    private var assetLoadRequestID = UUID()

    /// Image view to be used for zoom in/out animation.
    open private(set) lazy var animationPlaceholderImageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// A view that displays currently playing video.
    open private(set) lazy var playerView: PlayerView = components
        .playerView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        animationPlaceholderImageView.clipsToBounds = true
        animationPlaceholderImageView.contentMode = .scaleAspectFit
    }

    override open func setUpLayout() {
        super.setUpLayout()

        scrollView.addSubview(animationPlaceholderImageView)
        animationPlaceholderImageView.pin(anchors: [.height, .width], to: contentView)

        animationPlaceholderImageView.addSubview(playerView)
        playerView.pin(to: animationPlaceholderImageView)
        playerView.pin(anchors: [.height, .width], to: animationPlaceholderImageView)
    }

    override open func updateContent() {
        super.updateContent()

        let videoAttachment = content?.attachment(payloadType: VideoAttachmentPayload.self)
        let attachmentID = content?.id

        guard attachmentID != loadedAttachmentID else { return }
        loadedAttachmentID = attachmentID

        let requestID = UUID()
        assetLoadRequestID = requestID
        player.replaceCurrentItem(with: nil)
        updateAssetLoadingError(nil)

        if let url = videoAttachment?.videoURL {
            components.mediaLoader.loadVideoAsset(at: url) { [weak self] result in
                guard let self, self.assetLoadRequestID == requestID else { return }
                switch result {
                case let .success(loaded):
                    self.updateAssetLoadingError(nil)
                    self.player.replaceCurrentItem(with: AVPlayerItem(asset: loaded.asset))
                case let .failure(error):
                    self.updateAssetLoadingError(error)
                }
            }
        }

        if let videoAttachment {
            components.mediaLoader.loadVideoPreview(
                with: videoAttachment
            ) { [weak self] in
                guard let self, self.assetLoadRequestID == requestID else { return }
                switch $0 {
                case let .success(preview):
                    self.showPreview(using: preview.image)
                case .failure:
                    self.showPreview(using: nil)
                }
            }
        }
    }

    override open func prepareForReuse() {
        assetLoadRequestID = UUID()
        super.prepareForReuse()
        onAssetLoadingErrorChange = nil
    }

    private func showPreview(using thumbnail: UIImage?) {
        animationPlaceholderImageView.image = thumbnail
    }

    private func updateAssetLoadingError(_ error: Error?) {
        currentAssetLoadingError = error
        onAssetLoadingErrorChange?(error)
    }

    override open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        animationPlaceholderImageView
    }
}
