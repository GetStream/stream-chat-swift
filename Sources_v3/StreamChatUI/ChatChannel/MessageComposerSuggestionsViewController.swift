//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol SuggestionsViewControllerPresenter: class {
    func showSuggestionsViewController(
        with state: SuggestionsViewControllerState,
        onSelectItem: ((Int) -> Void)
    )
    func dismissSuggestionsViewController()

    var isSuggestionControllerPresented: Bool { get }
}

public enum SuggestionsViewControllerState {
    case commands([Command])
    case mentions([String])
}

open class MessageComposerSuggestionsViewController<ExtraData: ExtraDataTypes>: ViewController,
    UIConfigProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource {
    // MARK: - Underlying types

    public enum State {
        case commands([Command])
        case mentions([String])
    }

    // MARK: - Property

    private var frameObserver: NSKeyValueObservation?

    /// View to which the suggestions should be pinned.
    /// This view should be assigned as soon as instance of this
    /// class is instantiated, because we set observer to
    /// the bottomAnchorView as soon as we compute the height of the
    /// contentSize of the nested collectionView
    public var bottomAnchorView: UIView?
    
    public var state: SuggestionsViewControllerState? {
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

    open private(set) lazy var containerView: UIView = UIView().withoutAutoresizingMaskConstraints

    // MARK: - Overrides

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
    }

    override public func setUpAppearance() {
        view.backgroundColor = .clear
        view.layer.addShadow(color: uiConfig.colorPalette.shadow)
    }

    override public func setUpLayout() {
        view.embed(containerView)
        containerView.embed(
            collectionView,
            insets: .init(
                top: 0,
                leading: containerView.directionalLayoutMargins.leading,
                bottom: 0,
                trailing: containerView.directionalLayoutMargins.trailing
            )
        )

        collectionViewHeightObserver = collectionView.observe(
            \.contentSize,
            options: [.new],
            changeHandler: { [weak self] _, change in
                DispatchQueue.main.async {
                    guard let newSize = change.newValue, newSize.height < 300 else {
                        // TODO: Compute size better according to 4 cells.
                        self?.view.frame.size.height = 300
                        self?.updateViewFrame()
                        return
                    }
                    self?.view.frame.size.height = newSize.height
                    self?.updateViewFrame()
                }
            }
        )
        updateContent()
    }

    override open func updateContent() {
        collectionView.reloadData()
    }

    // MARK: - Private

    private func updateViewFrame() {
        frameObserver = bottomAnchorView?.observe(
            \.bounds,
            options: [.new, .initial],
            changeHandler: { [weak self] bottomAnchoredView, change in
                DispatchQueue.main.async {
                    guard let self = self, let changedFrame = change.newValue else { return }

                    let newFrame = bottomAnchoredView.convert(changedFrame, to: nil)
                    self.view.frame.origin.y = newFrame.minY - self.view.frame.height
                }
            }
        )
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
