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
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var viewAction: UIView!
    @IBOutlet weak var btnShowMore: UIButton!
    
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
        containerView.layer.cornerRadius = 12
        lblInfo.text = message?.text
        self.imgView.image = nil
        if let clickAction = message?.extraData.cta, clickAction == "url" {
            viewAction.isHidden = false
        } else {
            viewAction.isHidden = true
        }
        viewAction.isHidden = true
        if let hashTag = message?.extraData.tag {
            lblHashTag.text = "#" +  hashTag.joined(separator: " #")
        } else {
            lblHashTag.text = nil
        }
        if let imageAttachments = message?.imageAttachments.first {
            imgHeightConst.constant = 250
            self.imgView.image = nil
            self.btnShowMore.setTitle(getActionTitle(), for: .normal)
            self.imageUrl = imageAttachments.imageURL.absoluteString
            self.lblTitle.text = imageAttachments.title
            let options = ImageLoadingOptions(
                placeholder: Appearance.default.images.videoAttachmentPlaceholder,
                transition: .fadeIn(duration: 0.1)
            )
            Nuke.loadImage(with: imageAttachments.imageURL, options: options, into: imageView)
            playerView.isHidden = true
            videoURL = nil
        } else if let videoAttachment = message?.videoAttachments.first {
            videoURL = videoAttachment.videoURL.absoluteString
            imgHeightConst.constant = 250
            playerView.isHidden = false
            self.imgView.image = nil
            self.lblTitle.text = videoAttachment.title
            streamVideoLoader?.loadPreviewForVideo(at: videoAttachment.videoURL, completion: { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .success(let image):
                    self.imgView.image = image
                    self.imgPlay.isHidden = true
                case .failure(_):
                    self.imgPlay.isHidden = false
                    break
                }
            })
        } else {
            videoURL = nil
            imgView.image = nil
            playerView.isHidden = true
            imgHeightConst.constant = 0
        }
        self.layoutIfNeeded()
    }

    private func setupUI() {
        videoLayer.backgroundColor = UIColor.clear.cgColor
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.addSublayer(videoLayer)
    }
    
    private func getActionTitle() -> String {
        guard let cta = message?.extraData.cta else { return "Show More" }
        switch cta {
        case "url":  return "Show More"
        default: return ""
        }
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
