//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

/// A view that shows a playing video content.
open class PlayerView: _View {
    /// A player this view is following.
    open private(set) lazy var player = AVPlayer()
    
    override open func setUp() {
        super.setUp()
        
        playerLayer.player = player
    }
    
    public var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    
    override public static var layerClass: AnyClass {
        AVPlayerLayer.self
    }
}
