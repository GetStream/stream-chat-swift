//
//  ASVideoContainer.swift
//  Timeless-wallet
//
//  Created by Parth Kshatriya on 19/11/21.
//
//

import UIKit
import AVFoundation

class ASVideoContainer {
    var url: String
    var playOn: Bool {
        didSet {
            player.isMuted = ASVideoPlayerController.sharedVideoPlayer.mute
            playerItem.preferredPeakBitRate = ASVideoPlayerController.sharedVideoPlayer.preferredPeakBitRate
            if playOn && playerItem.status == .readyToPlay {
                player.play()
            } else {
                player.pause()
            }
        }
    }

    let player: AVPlayer
    let playerItem: AVPlayerItem

    init(player: AVPlayer, item: AVPlayerItem, url: String) {
        self.player = player
        self.playerItem = item
        self.url = url
        playOn = false
    }
}
