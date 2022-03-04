//
//  ASVideoTableViewCell.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 28/02/22.
//

import UIKit
import AVKit

open class ASVideoTableViewCell: UITableViewCell, ASAutoPlayVideoLayerContainer {

    // MARK: Variables
    public var videoURL: String? {
        didSet {
            if let videoURL = videoURL {
                ASVideoPlayerController.sharedVideoPlayer.setupVideoFor(url: videoURL)
            }
            videoLayer.isHidden = videoURL == nil
        }
    }
    
    public var imageUrl: String?
    public var isVideoPlaying: Bool = false
    public var videoLayer = AVPlayerLayer()
    
    // MARK: Outlets
    @IBOutlet open weak var imgView: UIImageView!
}
