//
//  JoinPrivateGroupVC.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 07/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import CoreLocation

class JoinPrivateGroupVC: UIViewController {

    // MARK: - Variables
    var controller: ChatChannelListController?
    var passWord = ""
    private var isChannelFetched = false
    private var memberListController: ChatChannelMemberListController?
    private var channelMembers: LazyCachedMapCollection<ChatChannelMember> = []
    private var channelController: ChatChannelController?
    weak var otpViewDelegate: PrivateGroupOTPVCDelegate?
    private var nearByChannel: ChatChannel?
    var userStatus: UserStatus? {
        didSet {
            if userStatus == .createGroup || userStatus == .alreadyJoined {
                btnJoinGroup.setTitle("Go To Chat", for: .normal)
            } else if userStatus == .joinGroup {
                btnJoinGroup.setTitle("Join This Group", for: .normal)
            }
        }
    }

    // MARK: - enums
    enum UserStatus {
        case createGroup
        case joinGroup
        case alreadyJoined
    }

    // MARK: - Outlets
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var lblOTP: UILabel!
    @IBOutlet weak var cvUserList: UICollectionView!
    @IBOutlet weak var btnJoinGroup: UIButton!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var viewJoinOverlay: UIView!
    @IBOutlet weak var safeAreaHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomSafeAreaHeight: NSLayoutConstraint!
    @IBOutlet weak var viewSafeAreaBottom: UIView!
    
    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - IBOutlets
    @IBAction func btnBackAction(_ sender: UIButton) {
        otpViewDelegate?.popToThisVC()
        popWithAnimation()
    }

    @IBAction func btnJoinGroupAction(_ sender: UIButton) {
        guard let channelController = channelController else {
            return
        }
        if userStatus == .joinGroup {
            viewJoinOverlay.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let `self` = self else { return }
                self.addMeInChannel(channelId: channelController.cid?.id ?? "") { error in
                    guard error == nil else {
                        Snackbar.show(text: "Something went wrong!")
                        self.viewJoinOverlay.isHidden = true
                        return
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.viewJoinOverlay.isHidden = true
                        self.handleNavigation()
                    }

                }
            }
        } else {
            handleNavigation()
        }
    }

    // MARK: - Functions
    private func setupUI() {
        safeAreaHeight.constant = UIView.safeAreaTop
        bottomSafeAreaHeight.constant = UIView.safeAreaBottom
        btnBack.setTitle("", for: .normal)
        btnBack.setImage(Appearance.default.images.backCircle, for: .normal)
        view.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        viewSafeAreaBottom.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        lblOTP.text = passWord
        lblOTP.textColor = .white
        lblOTP.setTextSpacingBy(value: 10)
        btnJoinGroup.backgroundColor = Appearance.default.colorPalette.themeBlue
        btnJoinGroup.layer.cornerRadius = 20
        cvUserList?.register(UINib(nibName: PrivateGroupUsersCVCell.identifier, bundle: nil),
                             forCellWithReuseIdentifier: PrivateGroupUsersCVCell.identifier)
        filterChannels()

        let imageAttachment = NSTextAttachment()
        imageAttachment.image = Appearance.default.images.handPointUp
        let joinString = NSMutableAttributedString(string: "Nearby friends can join by entering the ")
        joinString.append(NSAttributedString(attachment: imageAttachment))
        joinString.append(NSAttributedString(string: " secret code."))
        lblDescription.attributedText = joinString
        viewJoinOverlay.isHidden = true
    }

    private func handleNavigation() {
        guard let channelController = channelController else {
            return
        }
        let arrViewControllers = navigationController?.viewControllers ?? []
        guard let rootViewController = arrViewControllers.first else {
            return
        }
        var newControllers: [UIViewController] = []
        newControllers.append(rootViewController)

        let chatChannelVC = ChatChannelVC.init()
        chatChannelVC.channelController = channelController
        newControllers.append(chatChannelVC)
        navigationController?.setViewControllers(newControllers, animated: true)
    }

    private func filterChannels() {
        controller = ChatClient.shared.channelListController(
            query: .init(
                filter: .and([
                    .equal(.type, to: .privateMessaging),
                    .in("password", values: [passWord])
                ])))
        controller?.synchronize()
        controller?.delegate = self
    }

    private func createPrivateChannel() {
        let groupId = String(UUID().uuidString)
        let encodeGroupId = groupId.base64Encoded.string ?? ""
        let encodePassword = passWord.base64Encoded.string ?? ""
        
        let expiryDate = String(Date().withAddedHours(hours: 24).ticks).base64Encoded.string ?? ""
        var extraData: [String: RawJSON] = [:]
        extraData["isPrivateChat"] = .bool(true)
        extraData["password"] = .string(passWord)
        extraData["latitude"] = .string("\(LocationManager.shared.location.value.coordinate.latitude)")
        extraData["longitude"] = .string("\(LocationManager.shared.location.value.coordinate.longitude)")
        ChatClientConfiguration.shared.requestedPrivateGroupDynamicLink = { [weak self] dynamicLink in
            guard let self = self, let dynamicLink = dynamicLink else {
                Snackbar.show(text: "error while creating channel")
                return
            }
            extraData["joinLink"] = .string(dynamicLink.absoluteString)
            do {
                self.channelController = try ChatClient.shared.channelController(
                    createChannelWithId: .init(type: .privateMessaging, id: groupId),
                    name: "Unnamed private group",
                    members: [],
                    extraData: extraData)
                self.channelController?.synchronize{ [weak self] error in
                    guard error == nil, let self = self else {
                        return
                    }
                    if self.channelController?.channel?.lastMessageAt == nil {
                        var extraData = [String: RawJSON]()
                        self.channelController?.createNewMessage(
                            text: "",
                            pinning: nil,
                            attachments: [],
                            extraData: ["adminMessage": .string(self.channelController?.channel?.createdBy?.name ?? ""),
                                        "messageType": .string(AdminMessageType.privateChat.rawValue)],
                            completion: nil)
                    }
                    self.fetchChannelMembers(id: self.channelController?.channel?.cid.id ?? "")
                }
            } catch {
                Snackbar.show(text: "error while creating channel")
            }
        }
        ChatClientConfiguration.shared.requestPrivateGroupDynamicLink?(encodeGroupId, encodePassword, expiryDate)
    }

    private func addMeInChannel(channelId: String, completion: ((Error?) -> Void)? = nil) {
        guard let currentUserId = ChatClient.shared.currentUserId else {
            return
        }
        channelController?.addMembers(userIds: [currentUserId], completion: completion)
    }

    private func fetchChannelMembers(id: String) {
        memberListController = ChatClient.shared.memberListController(query: .init(cid: .init(type: .privateMessaging, id: id)))
        memberListController?.delegate = self
        memberListController?.synchronize()
        channelMembers = memberListController?.members ?? []
        cvUserList.reloadData()
    }

    private func getLatitude(raw: [String: RawJSON]?) -> Double? {
        guard let rawData = raw,
              let latitude = rawData["latitude"],
              let strLatitude = fetchRawData(raw: latitude) as? String
        else { return nil }
        return Double(strLatitude)
    }

    private func getLongitude(raw: [String: RawJSON]?) -> Double? {
        guard let rawData = raw,
              let longitude = rawData["longitude"],
              let strLongitude = fetchRawData(raw: longitude) as? String
        else { return nil }
        return Double(strLongitude)
    }

    private func getPassword(raw: [String: RawJSON]?) -> String? {
        guard let rawDate = raw,
              let password = rawDate["password"],
              let strPassword = fetchRawData(raw: password) as? String else {
            return nil
        }
        return strPassword
    }

    private func isChannelNearBy(_ channelData: [String: RawJSON]) -> Bool {
        guard let latitude = getLatitude(raw: channelData),
              let longitude = getLongitude(raw: channelData),
              let password = getPassword(raw: channelData) else {
                  return false
              }
        let coordinator = CLLocation(latitude: .init(latitude), longitude: .init(longitude))
        let distance = LocationManager.getDistanceInKm(from: coordinator, to: LocationManager.shared.location.value)
        if password == self.passWord && distance <= Constants.privateGroupRadius {
            return true
        } else {
            return false
        }
    }
}

// MARK: - ChannelList delegate
extension JoinPrivateGroupVC: ChatChannelListControllerDelegate {
    open func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        return true
    }

    open func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        return true
    }

    open func controller(_ controller: DataController, didChangeState state: DataController.State) {
        guard let channelController = self.controller, !isChannelFetched else {
            return
        }
         isChannelFetched = true
        switch state {
        case .localDataFetched, .remoteDataFetched:
            if channelController.channels.isEmpty {
                userStatus = .createGroup
                createPrivateChannel()
            } else {
                let nearByChannels = channelController.channels.filter { channel in
                    return isChannelNearBy(channel.extraData)
                }
                if nearByChannels.isEmpty {
                    userStatus = .createGroup
                    createPrivateChannel()
                } else {
                    guard let firstChannel = nearByChannels.first else {
                        return
                    }
                    let channelMembers = ChatClient.shared.memberListController(
                        query: .init(
                            cid: .init(
                                type: .privateMessaging,
                                id: firstChannel.cid.id)))

                    channelMembers.synchronize { [weak self] error in
                        guard error == nil, let self  = self else {
                            self?.popWithAnimation()
                            return
                        }
                        let isUserExiestInChat = !channelMembers.members.filter( {$0.id == ChatClient.shared.currentUserId}).isEmpty
                        if isUserExiestInChat {
                            self.userStatus = .alreadyJoined
                        } else {
                            self.userStatus = .joinGroup
                        }
                        self.channelController = ChatClient.shared.channelController(for: .init(type: .privateMessaging, id: firstChannel.cid.id))
                        self.fetchChannelMembers(id: firstChannel.cid.id)
                    }
                }
            }
        default:
            break
        }
    }
}

// MARK: - ChatChannelMemberListController Delegate
extension JoinPrivateGroupVC: ChatChannelMemberListControllerDelegate, ChatUserListControllerDelegate {
    func memberListController(_ controller: ChatChannelMemberListController, didChangeMembers changes: [ListChange<ChatChannelMember>]) {
        memberListController?.synchronize()
        channelMembers = memberListController?.members ?? []
        cvUserList.reloadData()
    }
}

// MARK: - CollectionView delegates
extension JoinPrivateGroupVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return channelMembers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PrivateGroupUsersCVCell.identifier, for: indexPath) as? PrivateGroupUsersCVCell
        else {
            return UICollectionViewCell()
        }
        let indexData = channelMembers[indexPath.row]
        cell.configData(data: indexData)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width / 4, height: (collectionView.frame.size.width / 4) + 25)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}
