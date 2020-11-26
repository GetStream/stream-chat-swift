//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelListVC<ExtraData: UIExtraDataTypes>: ViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIConfigProvider {
    override public func defaultAppearance() {
        title = "Stream Chat"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userAvatarView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createNewChannelButton)
        
        if #available(iOS 13.0, *) {
            collectionView.backgroundColor = .systemBackground
        } else {
            collectionView.backgroundColor = .white
        }
    }
    
    // MARK: - Properties
    
    public var controller: _ChatChannelListController<ExtraData>!
    
    public private(set) lazy var router = uiConfig.navigation.channelListRouter.init(rootViewController: self)
    
    public private(set) lazy var collectionView: ChatChannelListCollectionView = {
        let layout = uiConfig.channelList.channelCollectionLayout.init()
        let collection = uiConfig.channelList.channelCollectionView.init(layout: layout)
        collection.register(uiConfig.channelList.channelViewCell.self, forCellWithReuseIdentifier: "Cell")
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    public private(set) lazy var createNewChannelButton: CreateNewChannelButton = {
        let button = uiConfig.channelList.newChannelButton.init()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
        return button
    }()
    
    public private(set) lazy var userAvatarView: CurrentChatUserAvatarView<ExtraData> = {
        let avatar = uiConfig.currentUser.currentUserViewAvatarView.init(uiConfig: uiConfig)
        avatar.controller = controller.client.currentUserController()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.addTarget(self, action: #selector(didTapOnCurrentUserAvatar), for: .touchUpInside)
        return avatar
    }()
    
    // MARK: - Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.embed(collectionView)
        
        controller.setDelegate(self)
        controller.synchronize()
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        controller.channels.count
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "Cell",
            for: indexPath
        ) as! ChatChannelListCollectionViewCell<ExtraData>
    
        cell.uiConfig = uiConfig
        cell.channelView.channelAndUserId = (controller.channels[indexPath.row], controller.client.currentUserId)
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = controller.channels[indexPath.row]
        router.openChat(for: channel)
    }
    
    // MARK: - UIScrollViewDelegate
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.bounds.height
        guard bottomEdge >= scrollView.contentSize.height else { return }
        controller.loadNextChannels()
    }
    
    // MARK: Actions
    
    @objc open func didTapOnCurrentUserAvatar(_ sender: Any) {
        guard let currentUser = userAvatarView.controller?.currentUser else { return }
        
        router.openCurrentUserProfile(for: currentUser)
    }
    
    @objc open func didTapCreateNewChannel(_ sender: Any) {
        router.openCreateNewChannel()
    }
}

// MARK: - _ChatChannelListControllerDelegate

extension ChatChannelListVC: _ChatChannelListControllerDelegate {
    public func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    ) {
        collectionView.performBatchUpdates({
            for change in changes {
                switch change {
                case let .insert(_, index):
                    collectionView.insertItems(at: [index])
                case let .move(_, fromIndex, toIndex):
                    collectionView.moveItem(at: fromIndex, to: toIndex)
                case let .remove(_, index):
                    collectionView.deleteItems(at: [index])
                case let .update(_, index):
                    collectionView.reloadItems(at: [index])
                }
            }
        }, completion: nil)
    }
}
