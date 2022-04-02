//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import SwiftUI

public extension Notification.Name {
    static let pushToDaoChatMessageScreen = Notification.Name("pushToDaoChatMessageScreen")
}

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
    //
    public let lblTitle: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.setChatNavTitleColor()
        return lbl.withoutAutoresizingMaskConstraints
    }()
    //
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
        self.loadMoreChannels(collectionView: collectionView, forItemAt: indexPath)
        
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        headerSafeAreaView.backgroundColor = Appearance.default.colorPalette.chatNavBarBackgroundColor
        headerView.backgroundColor = Appearance.default.colorPalette.chatNavBarBackgroundColor
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pushToDaoChatMessageScreen(_:)),
            name: .pushToDaoChatMessageScreen,
            object: nil)
    }

    @objc private func pushToDaoChatMessageScreen(_ notification: NSNotification) {
        navigationController?.popToRootViewController(animated: false)
        guard let controller = notification.userInfo?["channelController"] as? ChatChannelController,
              let cid = controller.cid else {
            return
        }
        let chatChannelVC = ChatChannelVC.init()
        let channelController = ChatClient.shared.channelController(
            for: .init(type: .dao,
                       id: cid.id))
        chatChannelVC.channelController = channelController
        chatChannelVC.isChannelCreated = true
        self.pushWithAnimation(controller: chatChannelVC)
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.addSubview(headerSafeAreaView)
        NSLayoutConstraint.activate([
            headerSafeAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            headerSafeAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            headerSafeAreaView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            headerSafeAreaView.heightAnchor.constraint(equalToConstant: UIView.safeAreaTop)
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
        //
        headerView.addSubview(lblTitle)
        NSLayoutConstraint.activate([
            lblTitle.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 60),
            lblTitle.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0),
            lblTitle.centerXAnchor.constraint(equalTo: headerView.centerXAnchor, constant: 0),
            lblTitle.trailingAnchor.constraint(equalTo: createChannelButton.leadingAnchor, constant: -10),
        ])
        //
        
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

        collectionView.backgroundColor = Appearance.default.colorPalette.chatViewBackground
        
        if let flowLayout = collectionViewLayout as? ListCollectionViewLayout {
            flowLayout.itemSize = UICollectionViewFlowLayout.automaticSize
            flowLayout.separatorHeight = 0
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
        cell.itemView.titleLabel.setChatTitleColor()
        cell.itemView.subtitleLabel.setChatSubtitleBigColor()
        cell.swipeableView.delegate = self
        cell.swipeableView.indexPath = { [weak cell, weak self] in
            guard let cell = cell else { return nil }
            return self?.collectionView.indexPath(for: cell)
        }
        
        return cell
    }
    
//    open func collectionView(
//        _ collectionView: UICollectionView,
//        viewForSupplementaryElementOfKind kind: String,
//        at indexPath: IndexPath
//    ) -> UICollectionReusableView {
//        collectionView.dequeueReusableSupplementaryView(
//            ofKind: ListCollectionViewLayout.separatorKind,
//            withReuseIdentifier: separatorReuseIdentifier,
//            for: indexPath
//        )
//    }
        
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        NotificationCenter.default.post(name: .hideTabbar, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else {
                return
            }
            let channel = self.controller.channels[indexPath.row]
            self.router.showChannel(for: channel.cid)
        }
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

    open func loadMoreChannels(collectionView: UICollectionView, forItemAt indexPath: IndexPath) {
        
        if controller.state != .remoteDataFetched {
            return
        }
        guard let lastVisibleIndexPath = collectionView.indexPathsForVisibleItems.last else {
            return
        }
        guard indexPath.row == channelsCount - 1  else {
            return
        }
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

        let controller = self.controller.client.channelController(for: self.controller.channels[indexPath.row].cid)
        if controller.channelQuery.type == .announcement {
            let muteAction = CellActionView().withoutAutoresizingMaskConstraints
            if controller.channel?.isMuted ?? false {
                muteAction.actionButton.setImage(appearance.images.unMute, for: .normal)
            } else {
                muteAction.actionButton.setImage(appearance.images.mute, for: .normal)
            }
            muteAction.actionButton.backgroundColor = appearance.colorPalette.alert
            muteAction.actionButton.tintColor = appearance.colorPalette.text
            muteAction.action = { self.deleteButtonPressedForCell(at: indexPath) }
            return [muteAction]
        } else {
            let deleteView = CellActionView().withoutAutoresizingMaskConstraints
            deleteView.actionButton.setImage(appearance.images.messageActionDelete, for: .normal)
            deleteView.actionButton.backgroundColor = appearance.colorPalette.alert
            deleteView.actionButton.tintColor = .white
            deleteView.action = { self.deleteButtonPressedForCell(at: indexPath) }
            return [deleteView]
        }
    }

    /// This function is called when delete button is pressed from action items of a cell.
    /// - Parameter indexPath: IndexPath of given cell to fetch the content of it.
    open func deleteButtonPressedForCell(at indexPath: IndexPath) {
        var isbroadcastChannel = false
        var isMute = false
        let controller = self.controller.client.channelController(for: self.controller.channels[indexPath.row].cid)
        isbroadcastChannel = controller.channelQuery.type == .announcement
        isMute = controller.channel?.isMuted ?? false
        let deleteAction = UIAlertAction(title: isbroadcastChannel ? "\(isMute ? "Unmute" : "Mute")" : "Delete", style: .destructive) { [weak self] alert in
            guard let self = self else { return }
            let controller = self.controller.client.channelController(for: self.controller.channels[indexPath.row].cid)
            if isbroadcastChannel {
                guard let currentUserId = ChatClient.shared.currentUserId else { return }
                if controller.channel?.isMuted ?? false {
                    controller.unmuteChannel(completion: nil)
                    // Add user in channel to enable notification
                     controller.addMembers(userIds: [currentUserId], completion: nil)
                    return;
                }
                controller.muteChannel(completion: nil)
                // Remove user from channel to disable notification
                 controller.removeMembers(userIds: [currentUserId], completion: nil)
            } else {
                controller.hideChannel(clearHistory: true, completion: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            guard let self = self else {
                return
            }
            let cell = self.collectionView.cellForItem(at: indexPath) as? ChatChannelListCollectionViewCell
            cell?.swipeableView.close()
            Animate { [weak self] in
                guard let self = self else {
                    return
                }
                self.collectionView.layoutIfNeeded()
            }
        }
        var alertTitle = "Would you like to delete this conversation?\nIt'll be permanently deleted."
        if isbroadcastChannel {
            alertTitle = "Do you want to \(isMute ? "Unmute" : "Mute") this channel?"
        }
        let alert = UIAlertController.showAlert(title: alertTitle, message: nil, actions: [deleteAction, cancelAction], preferredStyle: .actionSheet)
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
