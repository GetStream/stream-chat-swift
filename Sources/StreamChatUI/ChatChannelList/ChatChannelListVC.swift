//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A `UIViewController` subclass  that shows list of channels.
public typealias ChatChannelListVC = _ChatChannelListVC<NoExtraData>

/// A `UIViewController` subclass  that shows list of channels.
open class _ChatChannelListVC<ExtraData: ExtraDataTypes>: _ViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UIConfigProvider {
    /// The `ChatChannelListController` instance that provides channels data.
    open var controller: _ChatChannelListController<ExtraData>!
    
    /// The `_ChatChannelListRouter` instance responsible for navigation.
    internal private(set) lazy var router: _ChatChannelListRouter<ExtraData> = uiConfig
        .navigation
        .channelListRouter.init(rootViewController: self)
    
    /// The `UICollectionViewLayout` that used by `ChatChannelListCollectionView`.
    internal private(set) lazy var collectionViewLayout: UICollectionViewLayout = uiConfig
        .channelList
        .channelCollectionLayout.init()
    
    /// The `UICollectionView` instance that displays channel list.
    internal private(set) lazy var collectionView: ChatChannelListCollectionView = uiConfig
        .channelList
        .channelCollectionView.init(layout: collectionViewLayout)
    
    /// The `UIButton` instance used for navigating to new channel screen creation,
    internal private(set) lazy var createNewChannelButton: UIButton = uiConfig
        .channelList
        .newChannelButton.init()
        .withoutAutoresizingMaskConstraints
    
    /// The `CurrentChatUserAvatarView` instance used for displaying avatar of the current user.
    internal private(set) lazy var userAvatarView: _CurrentChatUserAvatarView<ExtraData> = uiConfig
        .currentUser
        .currentUserViewAvatarView.init()
        .withoutAutoresizingMaskConstraints
    
    override internal func setUp() {
        super.setUp()
        
        controller.setDelegate(self)
        controller.synchronize()
        
        collectionView.register(uiConfig.channelList.channelViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        
        userAvatarView.controller = controller.client.currentUserController()
        userAvatarView.addTarget(self, action: #selector(didTapOnCurrentUserAvatar), for: .touchUpInside)
        
        createNewChannelButton.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
    }
    
    override internal func setUpLayout() {
        super.setUpLayout()
        
        view.embed(collectionView)
    }
    
    override internal func defaultAppearance() {
        title = "Stream Chat"
        
        navigationItem.backButtonTitle = ""
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userAvatarView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createNewChannelButton)
        
        collectionView.backgroundColor = uiConfig.colorPalette.background
    }
        
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        controller.channels.count
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "Cell",
            for: indexPath
        ) as! _ChatChannelListCollectionViewCell<ExtraData>
    
        cell.uiConfig = uiConfig
        cell.channelView.content = (controller.channels[indexPath.row], controller.client.currentUserId)
        
        return cell
    }
        
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channel = controller.channels[indexPath.row]
        router.openChat(for: channel)
    }
        
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let bottomEdge = scrollView.contentOffset.y + scrollView.bounds.height
        guard bottomEdge >= scrollView.contentSize.height else { return }
        controller.loadNextChannels()
    }
        
    @objc internal func didTapOnCurrentUserAvatar(_ sender: Any) {
        guard let currentUser = userAvatarView.controller?.currentUser else { return }
        
        router.openCurrentUserProfile(for: currentUser)
    }
    
    @objc internal func didTapCreateNewChannel(_ sender: Any) {
        router.openCreateNewChannel()
    }
}

extension _ChatChannelListVC: _ChatChannelListControllerDelegate {
    public typealias ExtraData = ExtraData
    
    open func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    ) {
        var movedItems: [IndexPath] = []
        collectionView.performBatchUpdates(
            {
                for change in changes {
                    switch change {
                    case let .insert(_, index):
                        collectionView.insertItems(at: [index])
                    case let .move(_, fromIndex, toIndex):
                        collectionView.moveItem(at: fromIndex, to: toIndex)
                        movedItems.append(toIndex)
                    case let .remove(_, index):
                        collectionView.deleteItems(at: [index])
                    case let .update(_, index):
                        collectionView.reloadItems(at: [index])
                    }
                }
            },
            completion: { _ in
                // Move changes from NSFetchController also can mean an update of the content.
                // Since a `moveItem` in collections do not update the content of the cell, we need to reload those cells.
                self.collectionView.reloadItems(at: movedItems)
            }
        )
    }
}
