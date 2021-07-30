//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
        
        let newAssetURL = videoAttachment?.videoURL
        let currentAssetURL = (player.currentItem?.asset as? AVURLAsset)?.url

        if newAssetURL != currentAssetURL {
            let playerItem = newAssetURL.map { AVPlayerItem(url: $0) }
            player.replaceCurrentItem(with: playerItem)
            
            if let url = newAssetURL {
                components.videoPreviewLoader.loadPreviewForVideo(at: url) { [weak self] in
                    switch $0 {
                    case let .success(preview):
                        self?.animationPlaceholderImageView.image = preview
                    case .failure:
                        self?.animationPlaceholderImageView.image = nil
                    }
                }
            }
        }
    }
    
    override open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        animationPlaceholderImageView
    }
}
