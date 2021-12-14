//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import SwiftUI

/// A `UIViewController` subclass  that shows list of channels.
@available(iOSApplicationExtension, unavailable)
open class ChatChannelListVC: _ViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    ChatChannelListControllerDelegate,
    DataControllerStateDelegate,
    ThemeProvider,
    SwipeableViewDelegate {
    /// The `ChatChannelListController` instance that provides channels data.
    public var controller: ChatChannelListController!

    private var loadingPreviousMessages: Bool = false

    open private(set) lazy var loadingIndicator: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .large).withoutAutoresizingMaskConstraints
        } else {
            return UIActivityIndicatorView(style: .whiteLarge).withoutAutoresizingMaskConstraints
        }
    }()
    
    /// A router object responsible for handling navigation actions of this view controller.
    open lazy var router: ChatChannelListRouter = components
        .channelListRouter
        .init(rootViewController: self)
    
    /// The `UICollectionViewLayout` that used by `ChatChannelListCollectionView`.
    open private(set) lazy var collectionViewLayout: UICollectionViewLayout = components
        .channelListLayout.init()
    
    /// The `UICollectionView` instance that displays channel list.
    open private(set) lazy var collectionView: UICollectionView =
        UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
            .withoutAutoresizingMaskConstraints

    open private(set) lazy var headerSafeAreaView: UIView = UIView(frame: .zero).withoutAutoresizingMaskConstraints

    open private(set) lazy var headerView: UIView = UIView(frame: .zero).withoutAutoresizingMaskConstraints

    open private(set) lazy var createChannelButton: UIButton = {
        let button = UIButton()
        button.setImage(appearance.images.editCircle, for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
        return button.withoutAutoresizingMaskConstraints
    }()
    open var createChannelAction: (() -> Void)?

    /// The `CurrentChatUserAvatarView` instance used for displaying avatar of the current user.
    open private(set) lazy var userAvatarView: CurrentChatUserAvatarView = components
        .currentUserAvatarView.init()
        .withoutAutoresizingMaskConstraints
    
    /// Reuse identifier of separator
    open var separatorReuseIdentifier: String { "CellSeparatorIdentifier" }
    
    /// Reuse identifier of `collectionViewCell`
    open var collectionViewCellReuseIdentifier: String { "Cell" }
    
    /// We use private property for channels count so we can update it inside `performBatchUpdates` as [documented](https://developer.apple.com/documentation/uikit/uicollectionview/1618045-performbatchupdates#discussion)
    private var channelsCount = 0

    /// Used for mapping `ListChanges` to sets of `IndexPath` and verifying possible conflicts
    private let collectionUpdatesMapper = CollectionUpdatesMapper()

    override open func setUp() {
        super.setUp()
        headerSafeAreaView.backgroundColor = appearance.colorPalette.walletTabbarBackground
        headerView.backgroundColor = appearance.colorPalette.walletTabbarBackground
        navigationController?.navigationBar.isHidden = true
        controller.delegate = self
        controller.synchronize()
        channelsCount = controller.channels.count
        
        collectionView.register(
            components.channelCell.self,
            forCellWithReuseIdentifier: collectionViewCellReuseIdentifier
        )
        
        collectionView.register(
            components.channelCellSeparator,
            forSupplementaryViewOfKind: ListCollectionViewLayout.separatorKind,
            withReuseIdentifier: separatorReuseIdentifier
        )

        collectionView.dataSource = self
        collectionView.delegate = self
        
        userAvatarView.controller = controller.client.currentUserController()
        userAvatarView.addTarget(self, action: #selector(didTapOnCurrentUserAvatar), for: .touchUpInside)
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if controller.state != .remoteDataFetched {
            return
        }

        if indexPath.row < collectionView.numberOfItems(inSection: 0) - 10 {
            return
        }

        loadMoreChannels()
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(headerSafeAreaView)
        NSLayoutConstraint.activate([
            headerSafeAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            headerSafeAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            headerSafeAreaView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            headerSafeAreaView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
        ])

        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            headerView.topAnchor.constraint(equalTo: headerSafeAreaView.bottomAnchor, constant: 0),
            headerView.heightAnchor.constraint(equalToConstant: 44)
        ])

        headerView.addSubview(userAvatarView)
        NSLayoutConstraint.activate([
            userAvatarView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            userAvatarView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0)
        ])

        headerView.addSubview(createChannelButton)
        NSLayoutConstraint.activate([
            createChannelButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            createChannelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0),
            createChannelButton.heightAnchor.constraint(equalToConstant: 32),
            createChannelButton.widthAnchor.constraint(equalToConstant: 32),
        ])

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
        collectionView.addSubview(loadingIndicator)
        loadingIndicator.pin(anchors: [.centerX, .centerY], to: view)
    }
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        title = "Stream Chat"
        
        //navigationItem.backButtonTitle = ""
        //navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userAvatarView)

        collectionView.backgroundColor = appearance.colorPalette.background

        if let flowLayout = collectionViewLayout as? ListCollectionViewLayout {
            flowLayout.itemSize = UICollectionViewFlowLayout.automaticSize
            flowLayout.estimatedItemSize = .init(
                width: collectionView.bounds.width,
                height: 64
            )
        }
    }

    @objc func didTapCreateNewChannel(_ sender: Any) {
        createChannelAction?()
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        channelsCount
    }
    
    open func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: collectionViewCellReuseIdentifier,
            for: indexPath
        ) as! ChatChannelListCollectionViewCell
    
        cell.components = components
        cell.itemView.content = .init(
            channel: controller.channels[indexPath.row],
            currentUserId: controller.client.currentUserId
        )

        cell.swipeableView.delegate = self
        cell.swipeableView.indexPath = { [weak cell, weak self] in
            guard let cell = cell else { return nil }
            return self?.collectionView.indexPath(for: cell)
        }
        
        return cell
    }
    
    open func collectionView(
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
        router.showChannel(for: channel.cid)
    }
        
    @objc open func didTapOnCurrentUserAvatar(_ sender: Any) {
        router.showCurrentUserProfile()
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

    open func loadMoreChannels() {
        guard !loadingPreviousMessages else {
            return
        }
        loadingPreviousMessages = true

        controller.loadNextChannels(completion: { [weak self] _ in
            self?.loadingPreviousMessages = false
        })
    }

    open func swipeableViewWillShowActionViews(for indexPath: IndexPath) {
        // Close other open cells
        collectionView.visibleCells.forEach {
            let cell = ($0 as? ChatChannelListCollectionViewCell)
            cell?.swipeableView.close()
        }

        Animate { self.collectionView.layoutIfNeeded() }
    }

    open func swipeableViewActionViews(for indexPath: IndexPath) -> [UIView] {
        let deleteView = CellActionView().withoutAutoresizingMaskConstraints
        deleteView.actionButton.setImage(appearance.images.messageActionDelete, for: .normal)

        deleteView.actionButton.backgroundColor = appearance.colorPalette.alert
        deleteView.actionButton.tintColor = .white

        deleteView.action = { self.deleteButtonPressedForCell(at: indexPath) }

        /*let moreView = CellActionView().withoutAutoresizingMaskConstraints
        moreView.actionButton.setImage(appearance.images.more, for: .normal)

        moreView.actionButton.backgroundColor = appearance.colorPalette.background1
        moreView.actionButton.tintColor = appearance.colorPalette.text

        moreView.action = { self.moreButtonPressedForCell(at: indexPath) }

        return [moreView, deleteView]*/
        return [deleteView]
    }

    /// This function is called when delete button is pressed from action items of a cell.
    /// - Parameter indexPath: IndexPath of given cell to fetch the content of it.
    open func deleteButtonPressedForCell(at indexPath: IndexPath) {
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] alert in
            guard let self = self else { return }
            let controller = self.controller.client.channelController(for: self.controller.channels[indexPath.row].cid)
            controller.hideChannel(clearHistory: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        let alert = UIAlertController.showAlert(title: "Would you like to delete this conversation?", message: nil, actions: [deleteAction, cancelAction], preferredStyle: .actionSheet)
        self.present(alert, animated: true, completion: nil)
    }

    /// This function is called when more button is pressed from action items of a cell.
    /// - Parameter indexPath: IndexPath of given cell to fetch the content of it.
    open func moreButtonPressedForCell(at indexPath: IndexPath) {
        router.didTapMoreButton(for: controller.channels[indexPath.row].cid)
    }
    
    // MARK: - ChatChannelListControllerDelegate
    
    open func controllerWillChangeChannels(_ controller: ChatChannelListController) {
        channelsCount = controller.channels.count
        collectionView.layoutIfNeeded()
    }
    
    open func controller(
        _ controller: ChatChannelListController,
        didChangeChannels changes: [ListChange<ChatChannel>]
    ) {
        guard let indices = collectionUpdatesMapper.mapToSetsOfIndexPaths(
            changes: changes,
            onConflict: {
                channelsCount = controller.channels.count
                collectionView.reloadData()
            }
        ) else { return }

        collectionView.performBatchUpdates(
            {
                collectionView.deleteItems(at: Array(indices.remove))
                collectionView.insertItems(at: Array(indices.insert))
                collectionView.reloadItems(at: Array(indices.update))
                indices.move.forEach {
                    collectionView.moveItem(at: $0.fromIndex, to: $0.toIndex)
                }
                
                channelsCount = controller.channels.count
            },
            completion: { _ in
                // Move changes from NSFetchController also can mean an update of the content.
                // Since a `moveItem` in collections do not update the content of the cell, we need to reload those cells.
                self.collectionView.reloadItems(at: Array(indices.move.map(\.toIndex)))
            }
        )
    }
    
    open func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        true
    }
    
    open func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        true
    }
    
    // MARK: - DataControllerStateDelegate
    
    open func controller(_ controller: DataController, didChangeState state: DataController.State) {
        switch state {
        case .initialized, .localDataFetched:
            if self.controller.channels.isEmpty {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
        default:
            loadingIndicator.stopAnimating()
        }
    }
}
