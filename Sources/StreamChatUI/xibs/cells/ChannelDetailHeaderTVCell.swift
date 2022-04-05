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
    func showWalletQRCode()
}

class ChannelDetailHeaderTVCell: _TableViewCell, AppearanceProvider {

    // MARK: - variables
    var channelController: ChatChannelController?
    var screenType: ChatGroupDetailViewModel.ScreenType?
    private var isChannelMuted = false
    weak var cellDelegate: ChannelDetailHeaderTVCellDelegate?
    var user: ChatChannelMember?
    var channelMembers = 0

    // MARK: - enum
    enum Tags: Int {
        case mute = 11
        case addOrShare = 12
        case leave = 13
    }

    // MARK: - outlets
    @IBOutlet weak var channelAvatar: ChatChannelAvatarView!
    @IBOutlet weak var userAvatar: ChatUserAvatarView!
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
    @IBOutlet weak var channelActionsTopSpacer: UIView!
    @IBOutlet var socialButtons: [UIButton]!
    @IBOutlet weak var btnEmail: UIButton!
    @IBOutlet weak var btnTwitter: UIButton!
    @IBOutlet weak var btnInsta: UIButton!
    @IBOutlet weak var btnTikTok: UIButton!

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
        if screenType == .userdetail || isDirectMessageChannel() {
            cellDelegate?.showWalletQRCode()
        } else {
            cellDelegate?.shareChannelLinkAction()
        }
    }

    @IBAction func btnEmailAction(_ sender: UIButton) {
    }

    @IBAction func btnTwitterAction(_ sender: UIButton) {
    }

    @IBAction func btnInstaAction(_ sender: UIButton) {
    }

    @IBAction func btnTiktokAction(_ sender: UIButton) {
    }

    // MARK: - functions
    private func setupUI() {
        channelAvatar.layer.cornerRadius = channelAvatar.frame.size.height / 2
        userAvatar.layer.cornerRadius = userAvatar.frame.size.height / 2
        channelActionText.map { $0.textColor = appearance.colorPalette.subTitleColor}
        for container in containers {
            container.backgroundColor = appearance.colorPalette.groupDetailContainerBG
            container.layer.cornerRadius = 12
            container.clipsToBounds = true
        }
        for btn in socialButtons {
            btn.layer.cornerRadius = 7
            btn.alpha = 0.2
        }
        btnEmail.setImage(appearance.images.socialMail, for: .normal)
        btnTwitter.setImage(appearance.images.socialTwitter, for: .normal)
        btnInsta.setImage(appearance.images.socialInsta, for: .normal)
        btnTikTok.setImage(appearance.images.socialTikTok, for: .normal)
    }

    func configCell(
        controller: ChatChannelController,
        screenType: ChatGroupDetailViewModel.ScreenType,
        members: Int,
        channelMember: ChatChannelMember?) {
            channelController = controller
            self.screenType = screenType
            user = channelMember
            channelMembers = members
            setupChannelContent()
        }

    private func setupChannelContent() {
        guard let channelController = channelController else {
            return
        }
        setTitleAndChannelAction()
        isChannelMuted = channelController.channel?.isMuted ?? false
        toggleChannelActionView()
        setAvatar()
        setSubTitle()
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
        if screenType == .userdetail {
            guard let chatUser = user else {
                return
            }
            walletAddressView()
            userNameView()
            bioView()
        } else if screenType == .channelDetail {
            if isDirectMessageChannel() {
                walletAddressView()
                userNameView()
                bioView()
            } else {
                shareLinkView()
                descriptionView()
            }
        }
    }

    private func toggleChannelActionView() {
        if screenType == .userdetail {
            viewChannelActions.isHidden = true
            channelActionsTopSpacer.isHidden = true
        } else {
            viewChannelActions.isHidden = false
            channelActionsTopSpacer.isHidden = false
        }
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

    private func setTitleAndChannelAction() {
        guard let channelController = channelController else {
            return
        }
        if screenType == .userdetail {
            lblTitle.text = user?.name ?? "-"
        } else if isDirectMessageChannel() {
            lblTitle.attributedText = getTitle(
                name: createChannelTitle(for: channelController.channel,
                                            ChatClient.shared.currentUserId ?? ""))
            centerContainerView.alpha = 0.5
            btnAddOrShare.isEnabled = false
        } else {
            lblTitle.attributedText = getTitle(name: channelController.channel?.name ?? "-")
            btnAddOrShare.isEnabled = true
        }
    }

    private func setAvatar() {
        if screenType == .userdetail {
            channelAvatar.isHidden = true
            userAvatar.isHidden = false
            guard let member = user,
                  let channelController = channelController else {
                return
            }
            userAvatar.content = member
        } else {
            channelAvatar.isHidden = false
            userAvatar.isHidden = true
            guard let channelController = channelController else {
                return
            }
            channelAvatar.content = (channelController.channel, ChatClient.shared.currentUserId)
        }
    }

    private func setSubTitle() {
        if isDirectMessageChannel() {
            guard let channel = channelController?.channel,
                  let otherMember = Array(channel.lastActiveMembers)
                    .first(where: { member in member.id != ChatClient.shared.currentUserId }) else {
                        return
                    }
            if otherMember.isOnline {
                lblSubTitle.text = "Online"
            } else if let lastActive = otherMember.lastActiveAt {
                lblSubTitle.text = "Last seen " + DTFormatter.formatter.string(from: lastActive)
            } else {
                lblSubTitle.text = "Never seen"
            }
        } else if screenType == .userdetail {
            guard let user = user else {
                return
            }
            if user.isOnline {
                lblSubTitle.text = "Online"
            } else if let lastActive = user.lastActiveAt {
                lblSubTitle.text = "Last seen " + DTFormatter.formatter.string(from: lastActive)
            } else {
                lblSubTitle.text = "Never seen"
            }
        } else {
            let totalFriends = max(channelMembers - 1, 0)
            if totalFriends <= 1 {
                lblSubTitle.text = "\(totalFriends) Friend"
            } else {
                lblSubTitle.text = "\(totalFriends) Friends"
            }
        }
    }
    
    private func getTitle(name: String) -> NSMutableAttributedString? {
        guard let iconImage = appearance.images.starCircleFill?
                .tinted(with: appearance.colorPalette.statusColorBlue) else {
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
        guard let stackSubView = ChannelDetailDescView.instanceFromNib() else {
            return
        }
        if screenType == .userdetail {
            guard let chatUser = user else {
                return
            }
            stackSubView.lblTitle.text = "wallet address"
            stackSubView.lblDesc.text = chatUser.id.trimStringByFirstLastCount(firstCount: 7, lastCount: 5)
            stackSubView.viewQRCode.isHidden = true
            stackSubView.viewSeparator.isHidden = false
            descStackView.addArrangedSubview(stackSubView)
        } else if screenType == .channelDetail {
            guard isDirectMessageChannel(),
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
    }

    private func userNameView() {
        guard let stackSubView = ChannelDetailDescView.instanceFromNib() else {
            return
        }
        if screenType == .userdetail {
            guard let chatUser = user else {
                return
            }
            stackSubView.lblTitle.text = "username"
            if let userName = chatUser.name {
                stackSubView.lblDesc.text = "@\(userName)"
            } else {
                stackSubView.lblDesc.text = "-"
            }
            stackSubView.viewQRCode.isHidden = false
            stackSubView.btnQRCode.addTarget(self, action: #selector(qrCodePressed(_:)), for: .touchUpInside)
            stackSubView.viewSeparator.isHidden = false
            descStackView.addArrangedSubview(stackSubView)
        } else  if screenType == .channelDetail {
            guard isDirectMessageChannel(),
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
        if (getChannelDescText()?.count ?? 0) == 0 {
            stackSubView.viewSeparator.isHidden = true
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
            descStackView.addArrangedSubview(stackSubView)
        }
    }

    private func descriptionView() {
        guard let stackSubView = ChannelDetailDescView.instanceFromNib() else {
            return
        }
        let descText = getChannelDescText()
        if (descText?.count ?? 0) > 0 {
            stackSubView.lblTitle.text = "description"
            stackSubView.lblDesc.text = descText
            stackSubView.viewQRCode.isHidden = true
            stackSubView.viewSeparator.isHidden = true
            descStackView.addArrangedSubview(stackSubView)
        }
    }

    private func getChannelDescText() -> String? {
        var descText: String?
        if channelController?.channel?.type == .dao {
            return channelController?.channel?.extraData.daoDescription
        } else {
            return channelController?.channel?.extraData.channelDescription
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
