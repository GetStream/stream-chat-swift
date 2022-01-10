//
//  JoinPrivateGroupVC.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 07/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class JoinPrivateGroupVC: UIViewController {

    // MARK: - Variables
    var controller: ChatChannelListController?
    var passWord = ""
    private var isChannelFetched = false
    private var memberListController: ChatChannelMemberListController?
    private var channelMembers: LazyCachedMapCollection<ChatChannelMember> = []

    // MARK: - Outlets
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var lblOTP: UILabel!
    @IBOutlet weak var cvUserList: UICollectionView!
    @IBOutlet weak var btnJoinGroup: UIButton!

    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - IBOutlets
    @IBAction func btnBackAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func btnJoinGroupAction(_ sender: UIButton) {
        
    }

    // MARK: - Functions
    private func setupUI() {
        btnBack.setTitle("", for: .normal)
        btnBack.setImage(Appearance.default.images.backCircle, for: .normal)
        lblOTP.text = passWord
        lblOTP.textColor = Appearance.default.colorPalette.themeBlue
        lblOTP.textDropShadow(color: Appearance.default.colorPalette.themeBlue)
        lblOTP.setTextSpacingBy(value: 10)
        btnJoinGroup.backgroundColor = Appearance.default.colorPalette.themeBlue
        btnJoinGroup.layer.cornerRadius = 6
        cvUserList?.register(UINib(nibName: PrivateGroupUsersCVCell.identifier, bundle: nil),
                             forCellWithReuseIdentifier: PrivateGroupUsersCVCell.identifier)
        filterChannels()
    }

    private func filterChannels() {
        controller = ChatClient.shared.channelListController(
            query: .init(
                filter: .and([
                    .equal(.type, to: .privateMessaging),
                    .equal("password", to: passWord)
                ])))
        controller?.synchronize()
        controller?.delegate = self
    }

    private func createPrivateChannel() {
        guard let currentUserId = ChatClient.shared.currentUserId else {
            return
        }
        do {
            var extraData: [String: RawJSON] = [:]
            extraData["isPrivateChat"] = .bool(true)
            extraData["password"] = .string(passWord)
            let channelController = try ChatClient.shared.channelController(
                createChannelWithId: .init(type: .privateMessaging, id: String(UUID().uuidString.prefix(10))),
                name: "temp group name",
                members: [],
                extraData: extraData)
            channelController.synchronize { [weak self] error in
                guard error == nil, let self = self else {
                    return
                }
                self.fetchChannelMembers(id: channelController.channel?.cid.id ?? "")
            }
        } catch {
            print("error while creating channel")
        }
    }

    private func addMeInChannel(channelId: String) {
        guard let currentUserId = ChatClient.shared.currentUserId else {
            return
        }
        let channelController = ChatClient.shared.channelController(for: .init(type: .privateMessaging, id: channelId))
        channelController.addMembers(userIds: [currentUserId], completion: nil)
        fetchChannelMembers(id: channelId)
    }

    private func fetchChannelMembers(id: String) {
        memberListController = ChatClient.shared.memberListController(query: .init(cid: .init(type: .privateMessaging, id: id)))
        memberListController?.delegate = self
        memberListController?.synchronize()
        channelMembers = memberListController?.members ?? []
        cvUserList.reloadData()
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
                createPrivateChannel()
            } else {
                guard let firstChannel = channelController.channels.first else {
                    return
                }
                addMeInChannel(channelId: firstChannel.cid.id)
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
