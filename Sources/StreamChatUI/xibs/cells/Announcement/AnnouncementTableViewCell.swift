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

class AnnouncementTableViewCell: ASVideoTableViewCell {

    // MARK: - Outlets
    //swiftlint:disable private_outlet
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imgPlay: UIImageView!
    @IBOutlet weak var viewOverlay: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lblHashTag: UILabel!
    @IBOutlet weak var lblInfo: UILabel!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var imgHeightConst: NSLayoutConstraint!
    
    // MARK: - Variables
    var content: ChatMessage?
    var streamVideoLoader: StreamVideoLoader?

    override func awakeFromNib() {
        super.awakeFromNib()
        playerView.layer.addSublayer(videoLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // TODO: - 3. Thumbnail placeholder jumps
        //Check for video frame issue on first time.
        videoLayer.frame = playerView.frame
    }

    func configureCell(_ message: ChatMessage?) {
        self.selectionStyle = .none
        containerView.layer.cornerRadius = 8
        lblInfo.text = message?.text
        streamVideoLoader = StreamVideoLoader()
        if let hashTag = message?.extraData.tag {
            lblHashTag.text = "#" +  hashTag.joined(separator: " #")
        }
        if let imageAttachments = message?.imageAttachments.first {
            imgHeightConst.constant = 250
            if imageAttachments.imageURL.pathExtension == "gif" {
                imgView.setGifFromURL(imageAttachments.imageURL)
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
    
//    func configCell(feed: FeedItem) {
//        lblDay.text = getDayString(feed.startDate)
//        lblMonth.text = getMonthString(feed.startDate).uppercased()
//        imgPlay.isHidden = true
//        if feed.attachment?.type == .video {
//            videoURL = feed.attachment?.url.absoluteString
//            imgView.kf.setImage(
//                with: feed.attachment?.videoThumbnail,
//                placeholder: UIImage(named: "placeholder"),
//                options: [.transition(.fade(0.1)), .loadDiskFileSynchronously]
//            ) { [weak self] result in
//                guard let `self` = self else { return }
//                switch result {
//                case .success(_):
//                    self.imgPlay.isHidden = false
//                case .failure(_): break
//                }
//            }
//            playerView.isHidden = false
//        } else if feed.attachment?.type == .image {
//            imgView.kf.setImage(
//                with: feed.attachment?.url,
//                placeholder: nil,
//                options: [.transition(.fade(0.1)), .loadDiskFileSynchronously])
//            self.imgPlay.isHidden = true
//            videoURL = nil
//            playerView.isHidden = true
//        } else {
//            playerView.isHidden = true
//            imgView.image = nil
//        }
//        lblTitle.text = feed.title
//        lblDetails.text = feed.details
//        lblInfo.text = feed.message
//        lblNoLikes.text = "\(feed.likesCount)"
//        lblHashTag.text = feed.hashtag
//    }
}

