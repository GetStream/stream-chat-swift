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
    UIConfigProvider,
    SwipeableViewDelegate {
    /// The `ChatChannelListController` instance that provides channels data.
    public var controller: _ChatChannelListController<ExtraData>!
    
    /// The `_ChatChannelListRouter` instance responsible for navigation.
    open private(set) lazy var router: _ChatChannelListRouter<ExtraData> = uiConfig
        .navigation
        .channelListRouter.init(rootViewController: self)
    
    /// The `UICollectionViewLayout` that used by `ChatChannelListCollectionView`.
    open private(set) lazy var collectionViewLayout: UICollectionViewLayout = uiConfig
        .channelList
        .collectionLayout.init()
    
    /// The `UICollectionView` instance that displays channel list.
    open private(set) lazy var collectionView: UICollectionView = uiConfig
        .channelList
        .collectionView.init(frame: .zero, collectionViewLayout: collectionViewLayout)
    
    /// The `UIButton` instance used for navigating to new channel screen creation,
    open private(set) lazy var createNewChannelButton: UIButton = uiConfig
        .channelList
        .newChannelButton.init()
        .withoutAutoresizingMaskConstraints
    
    /// The `CurrentChatUserAvatarView` instance used for displaying avatar of the current user.
    open private(set) lazy var userAvatarView: _CurrentChatUserAvatarView<ExtraData> = uiConfig
        .currentUser
        .currentUserViewAvatarView.init()
        .withoutAutoresizingMaskConstraints
    
    /// Reuse identifier of separator
    open var separatorReuseIdentifier: String { "CellSeparatorIdentifier" }
    
    /// Reuse identifier of `collectionViewCell`
    open var collectionViewCellReuseIdentifier: String { "Cell" }

    override open func setUp() {
        super.setUp()
        
        controller.setDelegate(self)
        controller.synchronize()
        
        collectionView.register(
            uiConfig.channelList.collectionViewCell.self,
            forCellWithReuseIdentifier: collectionViewCellReuseIdentifier
        )
        
        collectionView.register(
            uiConfig.channelList.cellSeparatorReusableView,
            forSupplementaryViewOfKind: ListCollectionViewLayout.separatorKind,
            withReuseIdentifier: separatorReuseIdentifier
        )

        collectionView.dataSource = self
        collectionView.delegate = self
        
        userAvatarView.controller = controller.client.currentUserController()
        userAvatarView.addTarget(self, action: #selector(didTapOnCurrentUserAvatar), for: .touchUpInside)
        
        createNewChannelButton.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        view.embed(collectionView)
    }
    
    override public func defaultAppearance() {
        title = "Stream Chat"
        
        navigationItem.backButtonTitle = ""
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userAvatarView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: createNewChannelButton)
        
        collectionView.backgroundColor = uiConfig.colorPalette.background

        if let flowLayout = collectionViewLayout as? ListCollectionViewLayout {
            flowLayout.itemSize = UICollectionViewFlowLayout.automaticSize
            flowLayout.estimatedItemSize = .init(
                width: collectionView.bounds.width,
                height: 64
            )
        }
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        controller.channels.count
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: collectionViewCellReuseIdentifier,
            for: indexPath
        ) as! _ChatChannelListCollectionViewCell<ExtraData>
    
        cell.uiConfig = uiConfig
        cell.itemView.content = (controller.channels[indexPath.row], controller.client.currentUserId)

        cell.swipeableView.delegate = self
        cell.swipeableView.indexPath = indexPath
        
        return cell
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        collectionView.dequeueReusableSupplementaryView(
            ofKind: ListCollectionViewLayout.separatorKind,
            withReuseIdentifier: separatorReuseIdentifier,
            for: indexPath
        )
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
        
    @objc open func didTapOnCurrentUserAvatar(_ sender: Any) {
        guard let currentUser = userAvatarView.controller?.currentUser else {
            log.error(
                "Current user is nil while tapping on CurrentUserAvatar, please check that both controller and currentUser are set"
            )
            return
        }
        router.openCurrentUserProfile(for: currentUser)
    }
    
    @objc open func didTapCreateNewChannel(_ sender: Any) {
        router.openCreateNewChannel()
    }

    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        collectionViewLayout.invalidateLayout()

        // Required to correctly setup navigation when view is wrapped
        // using UIHostingController and used in SwiftUI
        guard
            let parent = parent,
            parent.isUIHostingController
        else { return }

        if #available(iOS 13.0, *) {
            setupParentNavigation(parent: parent)
        }
    }

    public func swipeableViewWillShowActionViews(for indexPath: IndexPath) {
        // Close other open cells
        collectionView.visibleCells.forEach {
            let cell = ($0 as? _ChatChannelListCollectionViewCell<ExtraData>)
            cell?.swipeableView.close()
        }

        Animate { self.collectionView.layoutIfNeeded() }
    }

    public func swipeableViewActionViews(for indexPath: IndexPath) -> [UIView] {
        let deleteView = CellActionView().withoutAutoresizingMaskConstraints
        deleteView.actionButton.setImage(uiConfig.images.messageActionDelete, for: .normal)

        deleteView.actionButton.backgroundColor = uiConfig.colorPalette.alert
        deleteView.actionButton.tintColor = .white

        deleteView.action = { self.deleteButtonPressedForCell(at: indexPath) }

        let moreView = CellActionView().withoutAutoresizingMaskConstraints
        moreView.actionButton.setImage(uiConfig.images.more, for: .normal)

        moreView.actionButton.backgroundColor = uiConfig.colorPalette.background1
        moreView.actionButton.tintColor = uiConfig.colorPalette.text

        moreView.action = { self.moreButtonPressedForCell(at: indexPath) }

        return [moreView, deleteView]
    }

    /// This function is called when delete button is pressed from action items of a cell.
    /// - Parameter indexPath: IndexPath of given cell to fetch the content of it.
    open func deleteButtonPressedForCell(at indexPath: IndexPath) {}

    /// This function is called when delete more button is pressed from action items of a cell.
    /// - Parameter indexPath: IndexPath of given cell to fetch the content of it.
    open func moreButtonPressedForCell(at indexPath: IndexPath) {}
}

extension _ChatChannelListVC: _ChatChannelListControllerDelegate {
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
