//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerSuggestionsViewController<ExtraData: ExtraDataTypes>: ViewController,
    UIConfigProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Underlying types
    
    public enum State {
        case commands([Command])
        case mentions([String])
    }

    // MARK: - Property
    
    public var state: State? {
        didSet {
            updateContentIfNeeded()
        }
    }
    
    public var didSelectItemAt: ((Int) -> Void)?
    
    public var isPresented: Bool {
        view.superview != nil
    }

    private var collectionViewHeightObserver: NSKeyValueObservation?

    // MARK: - Subviews

    open private(set) lazy var collectionView = uiConfig
        .messageComposer
        .suggestionsCollectionView
        .init(layout: uiConfig.messageComposer.suggestionsCollectionViewLayout.init())
        .withoutAutoresizingMaskConstraints

    // MARK: - Overrides

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.embed(collectionView)
    }

    override open func setUp() {
        super.setUp()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            uiConfig.messageComposer.suggestionsCommandCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsCommandCollectionViewCell.reuseId
        )
        collectionView.register(
            uiConfig.messageComposer.suggestionsMentionCollectionViewCell,
            forCellWithReuseIdentifier: uiConfig.messageComposer.suggestionsMentionCollectionViewCell.reuseId
        )
        
        collectionViewHeightObserver = collectionView.observe(
            \.contentSize,
            options: [.new],
            changeHandler: { [weak self] _, change in
                DispatchQueue.main.async {
                    guard let self = self, let newSize = change.newValue else { return }
                    self.heightConstraint?.constant = newSize.height
                    self.view.setNeedsLayout()
                }
            }
        )
    }

    override public func setUpAppearance() {
        view.backgroundColor = .clear
        view.layer.addShadow(color: uiConfig.colorPalette.shadow)
    }

    override public func setUpLayout() {
        view.translatesAutoresizingMaskIntoConstraints = false

        heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 0)

        let constraints = [heightConstraint].compactMap { $0 }

        NSLayoutConstraint.activate(constraints)
        updateContent()
    }

    override open func updateViewConstraints() {
        super.updateViewConstraints()
        heightConstraint?.constant = collectionView.contentSize.height
    }

    override open func updateContent() {
        collectionView.reloadData()
    }

    // MARK: - UICollectionView

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let state = state else { return 0 }
        
        switch state {
        case let .commands(commands):
            return commands.count
        case let .mentions(users):
            return users.count
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let state = state else { return UICollectionViewCell() }
        
        switch state {
        case let .commands(commands):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MessageComposerCommandCollectionViewCell<ExtraData>.reuseId,
                for: indexPath
            ) as! MessageComposerCommandCollectionViewCell<ExtraData>
            
            cell.uiConfig = uiConfig
            
            cell.commandView.command = commands[indexPath.row]
            
            return cell
        // TODO: mentions
        case .mentions:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MessageComposerMentionCollectionViewCell<ExtraData>.reuseId,
                for: indexPath
            ) as! MessageComposerMentionCollectionViewCell<ExtraData>
            
            cell.uiConfig = uiConfig
            cell.mentionView.content = ("Damian", "@damian", UIImage(named: "pattern1", in: .streamChatUI), false)
            
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectItemAt?(indexPath.row)
    }
}
