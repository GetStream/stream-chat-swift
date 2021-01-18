//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

// TODO: Where to put this?
public enum ChatChannelDetailItemSetup {
    case notification
    case muteUser
    case blockUser
    case photosAndVideos
    case files
    case addGroup
    case muteGroup
    case leaveGroup
    case sharedGroups
}

open class ChatChannelUserDetailVC<ExtraData: ExtraDataTypes>: ViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UIConfigProvider {
    // MARK: - Properties
    
    private var navbarListener: ChatChannelNavigationBarListener<ExtraData>?
    
    private lazy var chatChannelSetup: [ChatChannelDetailItemSetup] = {
        let isDirect = channelController.channel?.isDirectMessageChannel ?? false
        return isDirect
            ? [.addGroup, .muteGroup, .photosAndVideos, .files, .leaveGroup]
            : [.notification, .muteUser, .blockUser, .photosAndVideos, .files, .sharedGroups]
    }()
    
    public var channelController: _ChatChannelController<ExtraData>!
    public lazy var membersController: _ChatChannelMemberListController<ExtraData>? = {
        guard let cid = self.channelController.channel?.cid else { return nil }
        return self.channelController
            .client
            .memberListController(query: .init(cid: cid))
    }()
    
    public private(set) lazy var router = uiConfig.navigation.channelRouter
    
    public private(set) lazy var collectionView: ChatChannelUserDetailCollectionView = {
        // TODO: should come from uiConfig
        let layout = ChatChannelUserDetailCollectionViewLayout()
        // TODO: should come from uiConfig
        let collection = ChatChannelUserDetailCollectionView(layout: layout)
        // TODO: should come from uiConfig
        collection.register(ChatChannelUserDetailCollectionViewCell<ExtraData>.self, forCellWithReuseIdentifier: "Cell")
        collection.register(
            ChatChannelUserDetailCollectionSectionView<ExtraData>.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ChatChannelUserDetailCollectionSectionView<ExtraData>.reuseId
        )
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    // MARK: - Life Cycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.embed(collectionView)
    }
    
    override public func defaultAppearance() {
        super.defaultAppearance()
        collectionView.backgroundColor = uiConfig.colorPalette.generalBackground
        
        /// Taken from ChatVC, TODO: Extract to a uiconfig component?
        let title = UILabel()
        title.textAlignment = .center
        title.font = .preferredFont(forTextStyle: .headline)

        let subtitle = UILabel()
        subtitle.textAlignment = .center
        subtitle.font = .preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = uiConfig.colorPalette.subtitleText

        let titleView = UIStackView(arrangedSubviews: [title, subtitle])
        titleView.axis = .vertical
        navigationItem.titleView = titleView
        
        // TODO: Not Working for Groups
        navbarListener = makeNavbarListener { data in
            title.text = data.title
            subtitle.text = data.subtitle
        }
    }
    
    // TODO: Possibly extract this from ChatVC to be possible to reuse in other VC's
    func makeNavbarListener(
        _ handler: @escaping (ChatChannelNavigationBarListener<ExtraData>.NavbarData) -> Void
    ) -> ChatChannelNavigationBarListener<ExtraData>? {
        guard let channel = channelController.channel else { return nil }
        let namer = uiConfig.messageList.channelNamer.init()
        let navbarListener = ChatChannelNavigationBarListener.make(for: channel.cid, in: channelController.client, using: namer)
        navbarListener.onDataChange = handler
        return navbarListener
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        2
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            // return channelController.channel?.memberCount ?? 0
            return 0
        case 1:
            return chatChannelSetup.count
        default:
            return 0
        }
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            return UICollectionViewCell()
        case 1:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "Cell",
                for: indexPath
            ) as! ChatChannelUserDetailCollectionViewCell<ExtraData>
            cell.uiConfig = uiConfig
            cell.channelDetailItemView.item = chatChannelSetup[indexPath.row]
            return cell
        default:
            return UICollectionViewCell()
        }
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ChatChannelUserDetailCollectionSectionView<ExtraData>.reuseId,
            for: indexPath
        ) as! ChatChannelUserDetailCollectionSectionView<ExtraData>
        return headerView
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        switch section {
        case 0: return .init(width: 0, height: 0)
        default: return .init(width: collectionView.frame.width, height: 8)
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // TODO:
    }
    
    // MARK: Actions
}

// MARK: - ItemVie
