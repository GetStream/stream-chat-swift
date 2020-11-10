//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

open class ChatChannelListViewController<ExtraData: ExtraDataTypes>: UICollectionViewController
    where ExtraData.Channel: NameAndImageProviding
{
    public required init(uiConfig: UIConfig<ExtraData>) {
        self.uiConfig = uiConfig
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var uiConfig: UIConfig<ExtraData>!
    
    public var controller: _ChatChannelListController<ExtraData>!
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        
        collectionView.register(ChannelCollectionViewCell<ExtraData>.self, forCellWithReuseIdentifier: "cell")
        
        controller.setDelegate(self)
        controller.synchronize()
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = .init(
            width: view.bounds.width,
            height: 50
        )
    }
    
    // MARK: - CollectionView data source

    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        controller.channels.count
    }
    
    override open func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ChannelCollectionViewCell<ExtraData>
        cell.config = uiConfig // TODO: move this to custom UICollectionView subclass `dequeueReusableCell` overload
        
        cell.load(controller.channels[indexPath.row])
                
        return cell
    }
}

extension ChatChannelListViewController: _ChatChannelListControllerDelegate {
    public func controller(
        _ controller: _ChatChannelListController<ExtraData>,
        didChangeChannels changes: [ListChange<_ChatChannel<ExtraData>>]
    ) {
        collectionView.reloadData()
    }
}

open class ChannelCollectionViewCell<ExtraData: ExtraDataTypes>: UICollectionViewCell
    where ExtraData.Channel: NameAndImageProviding
{
    public var config: UIConfig<ExtraData>!
    
    public lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        
        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(unreadIndicator)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.rightAnchor.constraint(equalTo: self.rightAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: self.leftAnchor)
        ])
        
        return stackView
    }()
    
    public lazy var textLabel: UILabel = .init()
    
    public lazy var unreadIndicator: UnreadIndicatorView = config.channelList.unreadIndicatorView.init(config: self.config)
    
    open func load(_ channel: _ChatChannel<ExtraData>) {
        textLabel.text = channel.displayName
        unreadIndicator.load(channel)
        
        _ = mainStackView
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class UnreadIndicatorView<ExtraData: ExtraDataTypes>: UIView {
    open func load(_ channel: _ChatChannel<ExtraData>) {
        isHidden = !channel.isUnread
    }
    
    override open var intrinsicContentSize: CGSize { .init(width: 20, height: 20) }
    
    public let config: UIConfig<ExtraData>

    public required init(config: UIConfig<ExtraData>) {
        self.config = config
        super.init(frame: .init(origin: .zero, size: .init(width: 20, height: 20)))
        
        UnreadIndicatorView<ExtraData>.appearance().backgroundColor = .red
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
