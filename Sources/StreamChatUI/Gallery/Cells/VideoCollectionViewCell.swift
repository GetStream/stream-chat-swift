//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// `UICollectionViewCell` for video gallery item.
public typealias VideoCollectionViewCell = _VideoCollectionViewCell<NoExtraData>

/// `UICollectionViewCell` for video gallery item.
open class _VideoCollectionViewCell<ExtraData: ExtraDataTypes>: _GalleryCollectionViewCell<ExtraData> {
    /// A cell reuse identifier.
    open class var reuseId: String { String(describing: self) }
    
    /// A player that handles the video content.
    public var player: AVPlayer {
        playerView.player
    }
    
    /// A view that displays currently playing video.
    open private(set) lazy var playerView: PlayerView = components
        .playerView.init()
        .withoutAutoresizingMaskConstraints
    
    override open func setUpLayout() {
        super.setUpLayout()
        
        scrollView.addSubview(playerView)
        playerView.pin(to: scrollView)
        playerView.pin(anchors: [.height, .width], to: contentView)
    }
    
    override open func updateContent() {
        super.updateContent()
        
        let videoAttachment = content?.attachment(payloadType: VideoAttachmentPayload.self)
        
        let newAssetURL = videoAttachment?.videoURL
        let currentAssetURL = (player.currentItem?.asset as? AVURLAsset)?.url

        if newAssetURL != currentAssetURL {
            let playerItem = newAssetURL.map { AVPlayerItem(url: $0) }
            player.replaceCurrentItem(with: playerItem)
        }
    }
    
    override open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        playerView
    }
}
