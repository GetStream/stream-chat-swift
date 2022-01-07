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
    /// We use private property for channels count so we can update it inside `performBatchUpdates` as [documented](https://developer.apple.com/documentation/uikit/uicollectionview/1618045-performbatchupdates#discussion)
    private var channelsCount = 0

    // MARK: - Outlets
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var lblOTP: UILabel!
    @IBOutlet weak var cvUserList: UICollectionView!

    // MARK: - View Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - IBOutlets
    @IBAction func btnBackAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Functions
    private func setupUI() {
        btnBack.setTitle("", for: .normal)
        btnBack.setImage(Appearance.default.images.backCircle, for: .normal)
        lblOTP.textColor = Appearance.default.colorPalette.themeBlue
        lblOTP.textDropShadow(color: Appearance.default.colorPalette.themeBlue)
        lblOTP.setTextSpacingBy(value: 10)
        cvUserList?.register(UINib(nibName: PrivateGroupUsersCVCell.identifier, bundle: nil), forCellWithReuseIdentifier: PrivateGroupUsersCVCell.identifier)
        filterChannels()
    }

    private func filterChannels() {
        controller = ChatClient.shared.channelListController(
            query: .init(
                filter: .or([
                    .containMembers(userIds: [ChatClient.shared.currentUserId!]),
                    .and([
                        .equal(.type, to: .privateMessaging),
                        .equal("password", to: passWord)
                    ])
                ])))
        controller?.synchronize()
        channelsCount = controller?.channels.count ?? 0
        if controller?.channels.count ?? 0 > 0 {
            print("channel exiest")
        } else {
            print("channel not exiest")
            //createPrivateChannel()
        }
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
                isCurrentUserMember: false,
                extraData: extraData)
            channelController.synchronize { error in
                print(error)
            }
        } catch {
            print("error while creating channel")
        }

    }
}

/*// MARK: - ChannelList delegate
extension JoinPrivateGroupVC: ChatChannelListControllerDelegate {
    open func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        return true
    }

    open func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        return true
    }

    open func controller(_ controller: DataController, didChangeState state: DataController.State) {
        guard let channelController = self.controller else {
            return
        }
        switch state {
        case .initialized, .localDataFetched:
            if channelController.channels.isEmpty {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
        default:
            loadingIndicator.stopAnimating()
        }
    }

    open func controllerWillChangeChannels(_ controller: ChatChannelListController) {
        channelsCount = controller.channels.count
    }

    open func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {
        channelsCount = controller.channels.count
    }
}*/

// MARK: - CollectionView delegates
extension JoinPrivateGroupVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PrivateGroupUsersCVCell.identifier, for: indexPath)
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
