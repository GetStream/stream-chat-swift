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

open class ChatChannelDetailVC<ExtraData: ExtraDataTypes>: ViewController,
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
    
    public private(set) lazy var collectionView: ChatChannelDetailCollectionView = {
        // TODO: should come from uiConfig
        let layout = ChatChannelDetailCollectionViewLayout()
        // TODO: should come from uiConfig
        let collection = ChatChannelDetailCollectionView(layout: layout)
        // TODO: should come from uiConfig
        collection.register(ChatChannelDetailCollectionViewCell<ExtraData>.self, forCellWithReuseIdentifier: "Cell")
        collection.register(
            ChatChannelDetailCollectionSectionReusableView<ExtraData>.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ChatChannelDetailCollectionSectionReusableView<ExtraData>.reuseId
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
            ) as! ChatChannelDetailCollectionViewCell<ExtraData>
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
            withReuseIdentifier: ChatChannelDetailCollectionSectionReusableView<ExtraData>.reuseId,
            for: indexPath
        ) as! ChatChannelDetailCollectionSectionReusableView<ExtraData>
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

// MARK: - CollectionView

open class ChatChannelDetailCollectionView: UICollectionView {
    public required init(layout: UICollectionViewLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - CollectionViewLayout

open class ChatChannelDetailCollectionViewLayout: UICollectionViewFlowLayout {
    // MARK: - Init
    
    override public init() {
        super.init()
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Overrides
    
    override open func prepare() {
        super.prepare()
        estimatedItemSize = .init(
            width: collectionView?.bounds.width ?? 0,
            height: 56
        )
    }
    
    // MARK: - Private
    
    private func setup() {
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0
    }
}

// MARK: - CollectionReusableView

open class ChatChannelDetailCollectionSectionReusableView<ExtraData: ExtraDataTypes>: UICollectionReusableView, UIConfigProvider {
    class var reuseId: String { String(describing: self) }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = uiConfig.colorPalette.channelDetailSectionHeaderBgColor
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - CollectionViewCell

open class ChatChannelDetailCollectionViewCell<ExtraData: ExtraDataTypes>: CollectionViewCell, UIConfigProvider {
    // MARK: - Properties

    public private(set) lazy var channelDetailItemView: ChatChannelDetailItemView<ExtraData> =
        uiConfig.channelDetail.channelDetailItemView.init()

    // MARK: Customizable

    override open func setUpLayout() {
        super.setUpLayout()
        contentView.embed(channelDetailItemView)
    }
}

// MARK: - ItemView

open class ChatChannelDetailItemView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    // MARK: - Properties
    
    public var item: ChatChannelDetailItemSetup? {
        didSet {
            updateContent()
        }
    }
    
    // MARK: - Subviews
    
    public private(set) lazy var iconView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        imageView.tintColor = uiConfig.colorPalette.channelDetailIconColor
        return imageView
    }()
    
    public private(set) lazy var titleLabel = UILabel().withoutAutoresizingMaskConstraints
    
    public private(set) lazy var accessoryView = UIView().withoutAutoresizingMaskConstraints
    
    private lazy var switchView: UISwitch = {
        let switchView = UISwitch().withoutAutoresizingMaskConstraints
        return switchView
    }()
   
    private lazy var indicatorView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .center
        imageView.tintColor = uiConfig.colorPalette.channelDetailIconColor
        imageView.image = uiConfig.channelDetail.icon.indicator
        return imageView
    }()

    // MARK: - Public

    override public func defaultAppearance() {
        super.defaultAppearance()
        backgroundColor = uiConfig.colorPalette.generalBackground
    }

    override open func setUpAppearance() {
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium) // TODO: Dominik's Typography PR
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(accessoryView)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.pin(equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.5),
            iconView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            iconView.widthAnchor.pin(equalToConstant: 20),
            titleLabel.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor),
            titleLabel.leadingAnchor.pin(equalToSystemSpacingAfter: iconView.trailingAnchor, multiplier: 2),
            accessoryView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor, constant: -8),
            accessoryView.centerYAnchor.pin(equalTo: layoutMarginsGuide.centerYAnchor)
        ])
    }
    
    override open func updateContent() {
        // TODO: Localization
        switch item {
        case .notification:
            titleLabel.text = "Notification"
            iconView.image = uiConfig.channelDetail.icon.notification
            accessoryView.embed(switchView)
        case .muteUser:
            titleLabel.text = "Mute User"
            iconView.image = uiConfig.channelDetail.icon.mute
            accessoryView.embed(switchView)
        case .addGroup:
            titleLabel.text = "Add a Group Name" // TODO: should be different cell type
            iconView.image = nil
        case .muteGroup:
            titleLabel.text = "Mute Group"
            iconView.image = uiConfig.channelDetail.icon.mute
            accessoryView.embed(switchView)
        case .leaveGroup:
            titleLabel.text = "Leave Group"
            iconView.image = uiConfig.channelDetail.icon.leaveGroup
        case .blockUser:
            titleLabel.text = "Block User"
            iconView.image = uiConfig.channelDetail.icon.block
            accessoryView.embed(switchView)
        case .photosAndVideos:
            titleLabel.text = "Photos & Video"
            iconView.image = uiConfig.channelDetail.icon.photosAndVideos
            accessoryView.embed(indicatorView)
        case .files:
            titleLabel.text = "Files"
            iconView.image = uiConfig.channelDetail.icon.files
            accessoryView.embed(indicatorView)
        case .sharedGroups:
            titleLabel.text = "Shared Groups"
            iconView.image = uiConfig.channelDetail.icon.groups
            accessoryView.embed(indicatorView)
        case .none:
            break
        }
    }
}
