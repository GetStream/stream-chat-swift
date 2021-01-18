//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatChannelUserDetailVC<ExtraData: ExtraDataTypes>: ViewController,
    UIConfigProvider,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {
    // MARK: - Properties
    
    open var actions: [[Action]] = []
    
    public var channelController: _ChatChannelController<ExtraData>!
    
    public private(set) lazy var router = uiConfig.navigation.channelRouter
    
    public private(set) lazy var collectionView: ChatChannelDetailCollectionView = {
        // TODO: should come from uiConfig
        let layout = ChatChannelDetailCollectionViewLayout()
        let collection = ChatChannelDetailCollectionView(layout: layout)
        collection.register(
            ChatChannelDetailDisplayActionCell<ExtraData>.self,
            forCellWithReuseIdentifier: ChatChannelDetailDisplayActionCell<ExtraData>.reuseId
        )
        collection.register(
            ChatChannelDetailSelectionActionCell<ExtraData>.self,
            forCellWithReuseIdentifier: ChatChannelDetailSelectionActionCell<ExtraData>.reuseId
        )
        collection.register(
            ChatChannelDetailDestructiveActionCell<ExtraData>.self,
            forCellWithReuseIdentifier: ChatChannelDetailDestructiveActionCell<ExtraData>.reuseId
        )
        collection.register(
            ChatChannelDetailToggleActionCell<ExtraData>.self,
            forCellWithReuseIdentifier: ChatChannelDetailToggleActionCell<ExtraData>.reuseId
        )
        collection.register(
            ChatChannelDetailCollectionSectionView<ExtraData>.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ChatChannelDetailCollectionSectionView<ExtraData>.reuseId
        )
        collection.register(
            ChatChannelDetailCollectionHeaderView<ExtraData>.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ChatChannelDetailCollectionHeaderView<ExtraData>.reuseId
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
    
    override open func setUp() {
        super.setUp()
        actions.append([
            Action.display(
                title: "@user",
                value: { [unowned self] _ in self.channelController.channel?.createdBy?.name ?? "" },
                action: nil
            )
        ])
        actions.append([
            Action.toggle(
                leadingIcon: uiConfig.channelDetail.icon.notification,
                title: "Notifications",
                action: { _, isOn in print("Notications Pressed (\(isOn))") }
            ),
            Action.toggle(
                leadingIcon: uiConfig.channelDetail.icon.mute,
                title: "Mute User",
                action: { _, isOn in print("Mute User Pressed (\(isOn))") }
            ),
            Action.toggle(
                leadingIcon: uiConfig.channelDetail.icon.block,
                title: "Block User",
                action: { _, isOn in print("Block User Pressed (\(isOn))") }
            ),
            Action.selection(
                leadingIcon: uiConfig.channelDetail.icon.photosAndVideos,
                title: "Photos & Video",
                trailingIcon: uiConfig.channelDetail.icon.indicator,
                action: { _ in print("Photos & Video Pressed") }
            ),
            Action.selection(
                leadingIcon: uiConfig.channelDetail.icon.files,
                title: "Files",
                trailingIcon: uiConfig.channelDetail.icon.indicator,
                action: { _ in print("Files Pressed") }
            ),
            Action.selection(
                leadingIcon: uiConfig.channelDetail.icon.sharedGroups,
                title: "Shared Groups",
                trailingIcon: uiConfig.channelDetail.icon.indicator,
                action: { _ in print("Shared Groups Pressed") }
            )
        ])
        actions.append([
            Action.destructive(
                leadingIcon: uiConfig.channelDetail.icon.delete,
                title: "Delete Contact",
                action: { _ in print("Delete Contact Pressed") }
            )
        ])
    }
    
    override public func defaultAppearance() {
        super.defaultAppearance()
        collectionView.backgroundColor = uiConfig.colorPalette.generalBackground
    }
    
    // MARK: - UICollectionViewDataSource
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        actions.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        actions[section].count
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let action: Action = actions[indexPath.section][indexPath.row]
        switch action {
        case let .toggle(leadingIcon, title, action):
            let cell = reuseCell(ChatChannelDetailToggleActionCell<ExtraData>.self, indexPath: indexPath)
            cell.channelDetailActionView.iconView.image = leadingIcon
            cell.channelDetailActionView.titleLabel.text = title
            cell.channelDetailActionView.onChange = { newValue in
                action(self, newValue)
            }
            return cell
        case let .selection(leadingIcon, title, trailingIcon, _):
            let cell = reuseCell(ChatChannelDetailSelectionActionCell<ExtraData>.self, indexPath: indexPath)
            cell.channelDetailActionView.leadingIconView.image = leadingIcon
            cell.channelDetailActionView.titleLabel.text = title
            cell.channelDetailActionView.trailingIconView.image = trailingIcon
            return cell
        case let .destructive(leadingIcon, title, _):
            let cell = reuseCell(ChatChannelDetailDestructiveActionCell<ExtraData>.self, indexPath: indexPath)
            cell.channelDetailActionView.iconView.image = leadingIcon
            cell.channelDetailActionView.titleLabel.text = title
            return cell
        case let .display(title, value, _):
            let cell = reuseCell(ChatChannelDetailDisplayActionCell<ExtraData>.self, indexPath: indexPath)
            cell.channelDetailActionView.titleLabel.text = title
            cell.channelDetailActionView.valueLabel.text = value(self)
            return cell
        }
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        switch indexPath.section {
        case 0:
            let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: ChatChannelDetailCollectionHeaderView<ExtraData>.reuseId,
                for: indexPath
            ) as! ChatChannelDetailCollectionHeaderView<ExtraData>
            headerView.channel = channelController.channel
            return headerView
        default:
            let sectionSeperatorView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: ChatChannelDetailCollectionSectionView<ExtraData>.reuseId,
                for: indexPath
            ) as! ChatChannelDetailCollectionSectionView<ExtraData>
            return sectionSeperatorView
        }
    }
    
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        switch section {
        case 0: return .init(width: collectionView.frame.width, height: 130)
        default: return .init(width: collectionView.frame.width, height: 8)
        }
    }
    
    // MARK: - UICollectionViewDelegate
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let action: Action = actions[indexPath.section][indexPath.row]
        
        switch action {
        case .toggle:
            // The toggle action is triggered by the UISwitch, not selecting the row.
            break
        case let .selection(_, _, _, action):
            action(self)
        case let .destructive(_, _, action):
            action(self)
        case let .display(_, _, action):
            action?(self)
        }
    }
    
    // MARK: - Helpers
    
    private func reuseCell<T: ChatChannelDetailActionCell>(_ type: T.Type, indexPath: IndexPath) -> T {
        collectionView
            .dequeueReusableCell(withReuseIdentifier: type.reuseId, for: indexPath) as! T
    }
}
