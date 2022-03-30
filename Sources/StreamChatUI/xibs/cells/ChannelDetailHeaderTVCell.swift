//
//  ChannelDetailHeaderTVCell.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 15/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

protocol ChannelDetailHeaderTVCellDelegate: class {
    func addFriendAction()
    func shareChannelLinkAction()
    func leaveChannel()
}

class ChannelDetailHeaderTVCell: _TableViewCell, AppearanceProvider {

    // MARK: - variables
    var channelController: ChatChannelController?
    var screenType: ChatGroupDetailViewModel.ScreenType?
    private var isChannelMuted = false
    weak var cellDelegate: ChannelDetailHeaderTVCellDelegate?

    // MARK: - enum
    enum Tags: Int {
        case mute = 11
        case addOrShare = 12
        case leave = 13
    }

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
    @IBOutlet weak var centerContainerView: UIView!
    @IBOutlet weak var btnAddOrShare: UIButton!
    @IBOutlet weak var viewChannelActions: UIView!
    @IBOutlet weak var channelActionsTop: NSLayoutConstraint! // 37, 0

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
        guard !isDirectMessageChannel() else {
            return
        }
        if isUserAdmin() {
            cellDelegate?.addFriendAction()
        } else {
            cellDelegate?.shareChannelLinkAction()
        }
    }

    @IBAction func btnLeaveAction(_ sender: UIButton) {
        cellDelegate?.leaveChannel()
    }

    @objc private func qrCodePressed(_ sender: UIButton) {
        cellDelegate?.shareChannelLinkAction()
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
        addChannelDescViews()
    }

    func configCell(
        controller: ChatChannelController,
        screenType: ChatGroupDetailViewModel.ScreenType,
        members: Int) {
        channelController = controller
        self.screenType = screenType
            setupChannelContent(members: members)
    }

    private func setupChannelContent(members: Int) {
        guard let channelController = channelController else {
            return
        }
        if isDirectMessageChannel() {
            lblTitle.attributedText = getTitle(
                name: createChannelTitle(for: channelController.channel,
                                            ChatClient.shared.currentUserId ?? ""))
            centerContainerView.alpha = 0.5
            btnAddOrShare.isEnabled = false
        } else {
            lblTitle.attributedText = getTitle(name: channelController.channel?.name ?? "-")
            btnAddOrShare.isEnabled = true
        }
        isChannelMuted = channelController.channel?.isMuted ?? false
        avatarView.content = (channelController.channel, ChatClient.shared.currentUserId)
        let totalFriends = max(members - 1, 0)
        if totalFriends <= 1 {
            lblSubTitle.text = "\(totalFriends) Friend"
        } else {
            lblSubTitle.text = "\(totalFriends) Friends"
        }
        setMuteButton()
        setMiddleButton()
        addChannelDescViews()
    }

    private func addChannelDescViews() {
        descStackView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        descStackView.customize(
            backgroundColor: appearance.colorPalette.groupDetailContainerBG,
            radiusSize: 12)
        if isDirectMessageChannel() {
            walletAddressView()
            userNameView()
            bioView()
        } else {
            shareLinkView()
            descriptionView()
        }
    }

    private func toggleChannelActionView(isHidden: Bool) {
        viewChannelActions.isHidden = isHidden
        channelActionsTop.constant = isHidden ? 0 : 37
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

    private func walletAddressView() {
        guard let stackSubView = ChannelDetailDescView.instanceFromNib(),
              isDirectMessageChannel(),
              let channel = channelController?.channel,
              let otherMember = Array(channel.lastActiveMembers)
            .first(where: { member in member.id != ChatClient.shared.currentUserId }) else {
            return
        }
        stackSubView.lblTitle.text = "wallet address"
        stackSubView.lblDesc.text = otherMember.id.trimStringByFirstLastCount(firstCount: 7, lastCount: 5)
        stackSubView.viewQRCode.isHidden = true
        stackSubView.viewSeparator.isHidden = false
        descStackView.addArrangedSubview(stackSubView)
    }

    private func userNameView() {
        guard let stackSubView = ChannelDetailDescView.instanceFromNib(),
              isDirectMessageChannel(),
              let channel = channelController?.channel,
              let otherMember = Array(channel.lastActiveMembers)
            .first(where: { member in member.id != ChatClient.shared.currentUserId }) else {
            return
        }
        stackSubView.lblTitle.text = "username"
        if let userName = otherMember.name {
            stackSubView.lblDesc.text = "@\(userName)"
        } else {
            stackSubView.lblDesc.text = "-"
        }
        stackSubView.viewQRCode.isHidden = false
        stackSubView.btnQRCode.addTarget(self, action: #selector(qrCodePressed(_:)), for: .touchUpInside)
        stackSubView.viewSeparator.isHidden = false
        descStackView.addArrangedSubview(stackSubView)
    }

    private func bioView() {
        guard let stackSubView = ChannelDetailDescView.instanceFromNib() else {
            return
        }
        stackSubView.lblTitle.text = "bio"
        stackSubView.lblDesc.text = "-"
        stackSubView.viewQRCode.isHidden = true
        stackSubView.viewSeparator.isHidden = true
        descStackView.addArrangedSubview(stackSubView)
    }

    private func shareLinkView() {
        guard let stackSubView = ChannelDetailDescView.instanceFromNib() else {
            return
        }
        var channelLink: String?
        if channelController?.channel?.type == .dao {
            channelLink = channelController?.channel?.extraData.daoJoinLink
        } else {
            channelLink = channelController?.channel?.extraData.joinLink
        }
        if channelLink != nil {
            stackSubView.lblTitle.text = "share link"
            stackSubView.lblDesc.text = channelLink
            stackSubView.viewQRCode.isHidden = false
            stackSubView.btnQRCode.addTarget(self, action: #selector(qrCodePressed(_:)), for: .touchUpInside)
            stackSubView.viewSeparator.isHidden = false
            descStackView.addArrangedSubview(stackSubView)
        }
    }

    private func descriptionView() {
        guard let stackSubView = ChannelDetailDescView.instanceFromNib() else {
            return
        }
        var descText: String?
        if channelController?.channel?.type == .dao {
            descText = channelController?.channel?.extraData.daoDescription
        } else {
            descText = channelController?.channel?.extraData.channelDescription
        }
        if descText != nil {
            stackSubView.lblTitle.text = "description"
            stackSubView.lblDesc.text = descText
            stackSubView.viewQRCode.isHidden = true
            stackSubView.viewSeparator.isHidden = true
            descStackView.addArrangedSubview(stackSubView)
        }
    }

    private func isDirectMessageChannel() -> Bool {
        if channelController?.channel?.isDirectMessageChannel ?? false {
            return true
        } else {
            return false
        }
    }
}

func createChannelTitle(for channel: ChatChannel?, _ currentUserId: UserId?) -> String {
    guard let channel = channel, let currentUserId = currentUserId else { return "Unnamed channel" }
    let channelName = channel.name ?? channel.cid.description
    if channel.isDirectMessageChannel {
        let otherMember = Array(channel.lastActiveMembers).first(where: { member in member.id != currentUserId })
        // Naming priority for a DM:
        // 1. other member's name
        // 2. other member's id
        // 3. channel name
        // 4. channel id
        if let otherMember = otherMember {
            if let otherMemberName = otherMember.name, !otherMemberName.isEmpty {
                return otherMemberName
            } else {
                return otherMember.id
            }
        } else {
            return channelName
        }
    } else {
        // Naming priority for a channel:
        // 1. channel name
        // 2. channel id
        return channelName
    }
}
