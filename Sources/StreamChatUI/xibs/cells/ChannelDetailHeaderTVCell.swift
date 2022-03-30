//
//  ChannelDetailHeaderTVCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 15/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class ChannelDetailHeaderTVCell: _TableViewCell, AppearanceProvider {

    // MARK: - variables
    var channelController: ChatChannelController?
    var screenType: ChatGroupDetailViewModel.ScreenType?
    private var isChannelMuted = false

    // MARK: - outlets
    @IBOutlet weak var avatarView: ChatChannelAvatarView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblSubTitle: UILabel!
    @IBOutlet var channelActionText: [UILabel]!
    @IBOutlet var containers: [UIView]!
    @IBOutlet weak var descStackView: UIStackView!
    @IBOutlet weak var imgMute: UIImageView!
    @IBOutlet weak var imgCenterAction: UIImageView!
    @IBOutlet weak var lblMute: UILabel!
    @IBOutlet weak var lblCenterAction: UILabel!

    // MARK: - view life cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    // MARK: - IB Actions
    @IBAction func btnChannelActionTouchDown(_ sender: UIButton) {
        guard let containerView = viewWithTag(sender.tag) as? UIView else {
            return
        }
        containerView.alpha = 0.5
    }

    @IBAction func btnChannelActionTouchOut(_ sender: UIButton) {
        guard let containerView = viewWithTag(sender.tag) as? UIView else {
            return
        }
        containerView.alpha = 1.0
    }

    @IBAction func btnMuteAction(_ sender: UIButton) {
        guard let channel = channelController?.channel else {
            return
        }
        if channel.isMuted {
            channelController?.unmuteChannel(completion: { [weak self] error in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    self.isChannelMuted = true
                    return
                }
                self.isChannelMuted = false
                Snackbar.show(text: "Notifications unmuted", messageType: StreamChatMessageType.ChatGroupMute)
                self.setMuteButton()
            })
        } else {
            channelController?.muteChannel(completion: { [weak self] error in
                guard let self = self else {
                    return
                }
                guard error == nil else {
                    self.isChannelMuted = false
                    return
                }
                self.isChannelMuted = true
                Snackbar.show(text: "Notifications muted", messageType: StreamChatMessageType.ChatGroupMute)
                self.setMuteButton()
            })
        }
    }

    @IBAction func btnShareOrAddFriendAction(_ sender: UIButton) {
        print(#function)
    }

    @IBAction func btnLeaveAction(_ sender: UIButton) {
        print(#function)
    }


    // MARK: - functions
    private func setupUI() {
        avatarView.layer.cornerRadius = avatarView.frame.size.height / 2
        for label in channelActionText {
            label.textColor = appearance.colorPalette.subTitleColor
        }
        for container in containers {
            container.backgroundColor = appearance.colorPalette.groupDetailContainerBG
            container.layer.cornerRadius = 12
            container.clipsToBounds = true
        }
        setupDescStackView()
    }

    func configCell(controller: ChatChannelController, screenType: ChatGroupDetailViewModel.ScreenType) {
        channelController = controller
        self.screenType = screenType
        setupChannelContent()
    }

    private func setupChannelContent() {
        guard let channelController = channelController else {
            return
        }
        isChannelMuted = channelController.channel?.isMuted ?? false
        lblTitle.attributedText = getTitle(name: channelController.channel?.name ?? "-")
        avatarView.content = (channelController.channel, ChatClient.shared.currentUserId)
        let totalFriends = max((channelController.channel?.memberCount ?? 0) - 1, 0)
        lblSubTitle.text = "\(totalFriends) Friends"
        setMuteButton()
        setMiddleButton()
    }

    private func setMuteButton() {
        if isChannelMuted {
            imgMute.image = appearance.images.bellSlash
            lblMute.text = "unmute"
        } else {
            imgMute.image = appearance.images.bell
            lblMute.text = "mute"
        }
    }

    private func setMiddleButton() {
        guard let channel = channelController?.channel else {
            return
        }
        if isUserAdmin() {
            // add friend
            imgCenterAction.image = appearance.images.personBadgePlus
            lblCenterAction.text = "Add"
        } else {
            // share link
            imgCenterAction.image = appearance.images.share
            lblCenterAction.text = "share"
        }
    }

    private func isUserAdmin() -> Bool {
        guard let channel = channelController?.channel else {
            return false
        }
        if channel.membership?.memberRole == .admin || channel.membership?.memberRole == .owner {
            return true
        } else {
            return false
        }
    }
    
    private func getTitle(name: String) -> NSMutableAttributedString? {
        guard let iconImage = appearance.images.starCircleFill?.tinted(with: appearance.colorPalette.statusColorBlue) else {
            return nil
        }
        let title = NSMutableAttributedString(string: "\(name) ")
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = iconImage
        imageAttachment.bounds = .init(
            x: 0,
            y: -((lblTitle.font.capHeight - iconImage.size.height).rounded() / 2) - 3,
            width: iconImage.size.width,
            height: iconImage.size.height)
        let imageString = NSAttributedString(attachment: imageAttachment)
        title.append(imageString)
        return title
    }

    private func setupDescStackView() {
        descStackView.customize(
            backgroundColor: appearance.colorPalette.groupDetailContainerBG,
            radiusSize: 12)
        descStackView.removeAllArrangedSubviews()
        if let stackSubView = ChannelDetailDescView.instanceFromNib() {
            descStackView.addArrangedSubview(stackSubView)
        }
        if let stackSubView1 = ChannelDetailDescView.instanceFromNib() {
            stackSubView1.viewQRCode.isHidden = true
            stackSubView1.viewSeparator.isHidden = true
            descStackView.addArrangedSubview(stackSubView1)
        }
    }
}
