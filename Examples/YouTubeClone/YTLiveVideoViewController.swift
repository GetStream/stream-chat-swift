//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import AVKit
import StreamChat
import UIKit

final class YTLiveVideoViewController: UIViewController {
    private let url =
        URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8")!
    
    @IBOutlet private var videoView: UIView!
    @IBOutlet private var chatView: UIView!
    @IBOutlet private var playPauseButton: UIButton!
    @IBOutlet private var videoViewHeightConstraint: NSLayoutConstraint!
    
    private var isPlaying = false
    
    private lazy var chatViewController: UIViewController = {
        let chatController = YTLiveChatViewController()
        return chatController
    }()
    
    private lazy var videoPlayer: AVPlayer = {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        return AVPlayer(playerItem: playerItem)
    }()
    
    private lazy var playerLayer: AVPlayerLayer = {
        AVPlayerLayer(player: videoPlayer)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoPlayer.play()
        isPlaying = true
        playPauseButton.tintColor = .white
        add(chatViewController, to: chatView)
        chatViewController.view.translatesAutoresizingMaskIntoConstraints = false
        chatView.addConstraints([
            chatViewController.view.heightAnchor.constraint(equalTo: chatView.heightAnchor),
            chatViewController.view.leadingAnchor.constraint(equalTo: chatView.leadingAnchor),
            chatViewController.view.widthAnchor.constraint(equalTo: chatView.widthAnchor),
            chatViewController.view.trailingAnchor.constraint(equalTo: chatView.trailingAnchor)
        ])
        
        videoView.layer.addSublayer(playerLayer)
        videoView.bringSubviewToFront(playPauseButton)
        setupUIAccordingToOrientation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Adjust the frame of the layer
        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = .resizeAspect
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { _ in
            self.setupUIAccordingToOrientation()
        }
    }
    
    @IBAction private func playPauseButtonTapped(_ sender: Any) {
        if isPlaying {
            videoPlayer.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            videoPlayer.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
        
        isPlaying = !isPlaying
    }
    
    // MARK: - Private Helpers
    
    private func setupUIAccordingToOrientation() {
        if UIDevice.current.orientation.isLandscape {
            videoViewHeightConstraint.isActive = false
            chatView.isHidden = true
            view.endEditing(true)
        } else {
            videoViewHeightConstraint.isActive = true
            chatView.isHidden = false
        }
    }
}

extension UIViewController {
    func add(_ child: UIViewController, to containerView: UIView) {
        child.willMove(toParent: self)
        addChild(child)
        containerView.addSubview(child.view)
        child.didMove(toParent: self)
    }
}
