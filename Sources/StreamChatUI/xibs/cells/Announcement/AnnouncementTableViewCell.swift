//
//  AnnouncementTableViewCell.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 28/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import Nuke
import StreamChat
import AVKit
import SwiftyGif

class AnnouncementTableViewCell: ASVideoTableViewCell {

    // MARK: - Outlets
    //swiftlint:disable private_outlet
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imgPlay: UIImageView!
    @IBOutlet weak var lblHashTag: UILabel!
    @IBOutlet weak var lblInfo: UILabel!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var imgHeightConst: NSLayoutConstraint!
    @IBOutlet weak var btnContainer: UIButton!
    
    // MARK: - Variables
    var content: ChatMessage?
    var streamVideoLoader: StreamVideoLoader?
    var didTapAnnouncement: (() -> Void)?
    var message: ChatMessage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoLayer.frame = playerView.frame
    }

    func configureCell(_ message: ChatMessage?) {
        self.selectionStyle = .none
        containerView.layer.cornerRadius = 8
        lblInfo.text = message?.text
        if let hashTag = message?.extraData.tag {
            lblHashTag.text = "#" +  hashTag.joined(separator: " #")
        }
        if let imageAttachments = message?.imageAttachments.first {
            imgHeightConst.constant = 250
            if imageAttachments.imageURL.pathExtension == "gif" {
                imgView.setGifFromURL(imageAttachments.imageURL, loopCount: 1)
                imgView.startAnimatingGif()
            } else {
                Nuke.loadImage(with: imageAttachments.imagePreviewURL, into: self.imgView)
            }
            playerView.isHidden = true
        } else if let videoAttachment = message?.videoAttachments.first {
            videoURL = videoAttachment.videoURL.absoluteString
            imgHeightConst.constant = 250
            playerView.isHidden = false
            self.imgView.image = nil
            streamVideoLoader?.loadPreviewForVideo(at: videoAttachment.videoURL, completion: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let image):
                    self.imgView.image = image
                case .failure(_):
                    break
                }
            })
        } else {
            playerView.isHidden = true
            imgHeightConst.constant = 0
        }
    }
    
    private func setupUI() {
        videoLayer.backgroundColor = UIColor.clear.cgColor
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.addSublayer(videoLayer)
    }
}

extension AnnouncementTableViewCell: GalleryItemPreview {
    var attachmentId: AttachmentId? {
        return message?.firstAttachmentId
    }
    
    override var imageView: UIImageView {
        self.imgView
    }
    
}
