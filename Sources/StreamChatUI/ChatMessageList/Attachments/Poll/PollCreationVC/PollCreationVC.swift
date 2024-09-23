//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The sections for the poll creation view.
public struct PollCreationSection: RawRepresentable, Equatable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The section to edit the name of the poll.
    public static var name = Self(rawValue: "name")
    /// The section to provide the options of the poll.
    public static var options = Self(rawValue: "options")
    /// THe section to enable or disable the poll features.
    public static var features = Self(rawValue: "features")
}

/// The sections for the poll creation view.
public struct PollFeatureType: Equatable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static var multipleVotes = Self(rawValue: "multiple-votes")
    public static var anonymous = Self(rawValue: "anonymous")
    public static var suggestions = Self(rawValue: "suggestions")
    public static var comments = Self(rawValue: "comments")

    public static func == (lhs: PollFeatureType, rhs: PollFeatureType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

/// The view controller to create a poll in a channel.
open class PollCreationVC:
    _ViewController,
    ThemeProvider,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UIAdaptivePresentationControllerDelegate {
    // MARK: - Dependencies

    /// The channel controller to create the poll in the given channel.
    public let channelController: ChatChannelController

    public required init(channelController: ChatChannelController) {
        self.channelController = channelController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Content

    /// The sections of the poll.
    public var sections: [PollCreationSection] = [
        .name,
        .options,
        .features
    ]

    /// The name of the poll.
    public var name: String = "" {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The available options of the poll.
    public var options: [String] = [""] {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The indices of the options that contain an error.
    public var optionsErrorIndices: [Int: String] = [:]

    /// The features supported to be enabled in the poll.
    public var pollFeatures: [PollFeatureType] = [
        .multipleVotes,
        .anonymous,
        .suggestions,
        .comments
    ]

    /// The multiple votes feature configuration.
    public var multipleVotesFeature = MultipleVotesPollFeature(
        name: "Multiple votes",
        isEnabled: false,
        config: .disabled
    )

    /// The anonymous feature configuration.
    public var anonymousFeature = BasicPollFeature(
        name: "Anonymous poll",
        isEnabled: false
    )

    /// The allow suggestions feature configuration.
    public var suggestionsFeature = BasicPollFeature(
        name: "Suggest an option",
        isEnabled: false
    )

    /// The allow comments feature configuration.
    public var commentsFeature = BasicPollFeature(
        name: "Add a comment",
        isEnabled: false
    )

    /// The current maximum votes input text.
    public var maximumVotesText: String = "" {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// The error in case the maximum votes is not valid.
    public var maximumVotesErrorText: String? {
        didSet {
            updateContentIfNeeded()
        }
    }

    /// A boolean value indicating if the user has made any changes to the poll or not.
    /// By default this boolean is used to check if the user wants to discard his changes or not.
    open var hasChanges: Bool {
        name.isEmpty == false || options.count > 1
    }

    /// A boolean value indicating if there are no errors and it is possible to create the poll.
    open var canCreatePoll: Bool {
        name.isEmpty == false
            && maximumVotesErrorText == nil
            && options.filter { !$0.isEmpty }.count >= 2
            && optionsErrorIndices.isEmpty
    }

    // MARK: - Views

    /// The collection view responsible to render the poll input data.
    open private(set) lazy var collectionView: UICollectionView = {
        let layout = makeCompositionalLayout()
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
            .withoutAutoresizingMaskConstraints
    }()

    /// The estimated cell height.
    open var estimatedCellHeight: CGFloat {
        56
    }

    /// The estimated section header height.
    open var estimatedSectionHeaderHeight: CGFloat {
        16
    }

    /// The leading spacing of the collection's view content.
    open var leadingSpacing: CGFloat {
        8
    }

    /// The trailing spacing of the collection's view content.
    open var trailingSpacing: CGFloat {
        8
    }

    /// Creates the composition layout for the collection view.
    open func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self = self else { return nil }
            let section = self.sections[sectionIndex]
            switch section {
            case .name:
                return self.makeNameSectionLayout()
            case .options:
                return self.makeOptionsSectionLayout()
            case .features:
                return self.makeFeaturesSectionLayout()
            default:
                return nil
            }
        }
    }

    /// Creates the layout for the name section.
    open func makeNameSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(estimatedCellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: leadingSpacing, bottom: 8, trailing: trailingSpacing)
        section.boundarySupplementaryItems = [makeSectionHeaderItem()]
        return section
    }

    /// Creates the layout for the options section.
    open func makeOptionsSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(estimatedCellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: leadingSpacing, bottom: 8, trailing: trailingSpacing)
        section.interGroupSpacing = 8
        section.boundarySupplementaryItems = [makeSectionHeaderItem()]
        return section
    }

    /// Creates the layout for the features section.
    open func makeFeaturesSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(estimatedCellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: leadingSpacing, bottom: 0, trailing: trailingSpacing)
        section.interGroupSpacing = 8
        section.boundarySupplementaryItems = [makeSectionHeaderItem()]
        return section
    }

    /// Creates the supplementary header view for each section.
    open func makeSectionHeaderItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(estimatedSectionHeaderHeight)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    /// The button to create the poll.
    open private(set) lazy var createPollButton = UIBarButtonItem(
        image: appearance.images.pollCreationSendIcon,
        style: .plain,
        target: self,
        action: #selector(createPoll)
    )

    open private(set) lazy var cancelButton = UIBarButtonItem(
        title: "Cancel",
        style: .plain,
        target: self,
        action: #selector(cancelPoll)
    )

    /// Component responsible for setting the correct offset when keyboard frame is changed.
    open lazy var keyboardHandler: KeyboardHandler = DefaultScrollViewKeyboardHandler(
        scrollView: self.collectionView
    )

    // MARK: - Lifecycle

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        keyboardHandler.start()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        keyboardHandler.stop()
    }

    override open func setUp() {
        super.setUp()

        navigationController?.presentationController?.delegate = self

        let longGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))
        longGestureRecognizer.minimumPressDuration = 0.3
        collectionView.addGestureRecognizer(longGestureRecognizer)

        collectionView.keyboardDismissMode = .onDrag
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(components.pollCreationNameCell)
        collectionView.register(components.pollCreationOptionCell)
        collectionView.register(components.pollCreationFeatureCell)
        collectionView.register(components.pollCreationMultipleVotesFeatureCell)
        collectionView.register(
            components.pollCreationSectionHeaderView,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: String(describing: components.pollCreationSectionHeaderView)
        )
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        title = "Create Poll"
        collectionView.backgroundColor = appearance.colorPalette.background
        navigationItem.rightBarButtonItems = [createPollButton]
        navigationItem.leftBarButtonItems = [cancelButton]
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(collectionView)
    }

    // MARK: - UICollectionViewDelegate & UICollectionViewDataSource

    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = sections[section]
        switch section {
        case .name:
            return 1
        case .options:
            return options.count
        case .features:
            return pollFeatures.count
        default:
            return 0
        }
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        switch section {
        case .name:
            return pollNameCell(at: indexPath)
        case .options:
            return pollOptionCell(at: indexPath)
        case .features:
            let feature = pollFeatures[indexPath.item]
            switch feature {
            case .multipleVotes:
                return pollMultipleVotesFeatureCell(at: indexPath)
            case .anonymous:
                return pollBasicFeatureCell(at: indexPath, feature: anonymousFeature)
            case .suggestions:
                return pollBasicFeatureCell(at: indexPath, feature: suggestionsFeature)
            case .comments:
                return pollBasicFeatureCell(at: indexPath, feature: commentsFeature)
            default:
                return UICollectionViewCell()
            }
        default:
            return UICollectionViewCell()
        }
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        let view = collectionView.dequeueReusableSupplementaryView(
            with: components.pollCreationSectionHeaderView,
            ofKind: kind,
            for: indexPath
        )

        let section = sections[indexPath.section]
        switch section {
        case .name:
            view.content = .init(title: "Question")
        case .options:
            view.content = .init(title: "Options")
        default:
            view.content = nil
        }

        return view
    }

    open func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section]
        switch section {
        case .options:
            let isAddNewOptionItem = indexPath.item == options.count - 1
            return !isAddNewOptionItem
        default:
            return false
        }
    }

    open func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = options[sourceIndexPath.row]
        options.remove(at: sourceIndexPath.row)
        options.insert(movedObject, at: destinationIndexPath.row)
    }

    open func collectionView(
        _ collectionView: UICollectionView,
        targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath,
        atCurrentIndexPath currentIndexPath: IndexPath,
        toProposedIndexPath proposedIndexPath: IndexPath
    ) -> IndexPath {
        switch sections[proposedIndexPath.section] {
        case .options:
            // Do not allow moving option after the cell to create a new option.
            if proposedIndexPath.item == options.count - 1 {
                return originalIndexPath
            }
            return proposedIndexPath
        default:
            return originalIndexPath
        }
    }

    // MARK: - Cell Configuration

    open func pollNameCell(at indexPath: IndexPath) -> PollCreationNameCell {
        let cell = collectionView.dequeueReusableCell(with: components.pollCreationNameCell, for: indexPath)
        cell.content = .init(
            placeholder: "Ask a question",
            errorText: nil
        )
        cell.setText(name)
        cell.onTextChanged = { [weak self] _, newValue in
            self?.name = newValue
        }
        cell.onReturnKeyPressed = { [weak self, weak collectionView] in
            guard let collectionView = collectionView else { return true }
            guard let optionsSectionIndex = self?.sections.firstIndex(of: .options) else { return true }
            let firstOptionIndexPath = IndexPath(item: 0, section: optionsSectionIndex)
            let cell = collectionView.cellForItem(at: firstOptionIndexPath) as? PollCreationOptionCell
            cell?.textFieldView.inputTextField.becomeFirstResponder()
            return false
        }
        return cell
    }

    open func pollOptionCell(at indexPath: IndexPath) -> PollCreationOptionCell {
        let isLastItem = indexPath.item == options.count - 1
        let cell = collectionView.dequeueReusableCell(with: components.pollCreationOptionCell, for: indexPath)
        let option = options[indexPath.item]
        cell.content = .init(
            placeholder: "Add an option",
            errorText: optionsErrorIndices[indexPath.item]
        )
        cell.reorderImageView.isHidden = option.isEmpty && isLastItem
        cell.setText(option)
        cell.onTextChanged = { [weak self, weak collectionView, weak cell] oldValue, newValue in
            guard let self = self else { return }
            guard let collectionView = collectionView else { return }
            guard let cell = cell else { return }
            guard indexPath.item < self.options.count else { return }

            cell.reorderImageView.isHidden = false
            self.options[indexPath.item] = newValue

            let numberOfOptions = self.options.count
            let isLastItem = indexPath.item == numberOfOptions - 1
            if isLastItem && !newValue.isEmpty {
                self.options.append("")
                let newIndexPath = IndexPath(item: indexPath.item + 1, section: indexPath.section)
                collectionView.insertItems(at: [newIndexPath])
            } else if oldValue.isEmpty && newValue.isEmpty && !isLastItem {
                self.options.remove(at: indexPath.item)
                collectionView.reloadData()
            }
        }
        cell.onReturnKeyPressed = { [weak self, weak collectionView, weak cell] in
            guard let collectionView = collectionView else { return true }
            guard let cell = cell else { return true }
            guard let optionsSectionIndex = self?.sections.firstIndex(of: .options) else { return true }
            guard let currentIndexPath = collectionView.indexPath(for: cell) else { return true }
            let nextOptionIndexPath = IndexPath(item: currentIndexPath.item + 1, section: optionsSectionIndex)
            guard let nextCell = collectionView.cellForItem(at: nextOptionIndexPath) as? PollCreationOptionCell else {
                self?.view.endEditing(true)
                return true
            }
            nextCell.textFieldView.inputTextField.becomeFirstResponder()
            return false
        }
        return cell
    }

    open func pollBasicFeatureCell(at indexPath: IndexPath, feature: PollFeature) -> PollCreationFeatureCell {
        let cell = collectionView.dequeueReusableCell(
            with: components.pollCreationFeatureCell,
            for: indexPath
        )
        cell.content = .init(featureName: feature.name)
        return cell
    }

    open func pollMultipleVotesFeatureCell(at indexPath: IndexPath) -> PollCreationMultipleVotesFeatureCell {
        let cell = collectionView.dequeueReusableCell(
            with: components.pollCreationMultipleVotesFeatureCell,
            for: indexPath
        )
        cell.content = .init(
            feature: multipleVotesFeature,
            maximumVotesErrorText: maximumVotesErrorText
        )
        cell.setMaximumVotesText(maximumVotesText)
        cell.onMaximumVotesValueChanged = { [weak self] maxVotes in
            self?.multipleVotesFeature.config.maxVotes = maxVotes
        }
        cell.onMaximumVotesTextChanged = { [weak self] text in
            self?.maximumVotesText = text
        }
        cell.onMaximumVotesErrorTextChanged = { [weak self] errorText in
            self?.maximumVotesErrorText = errorText
        }
        cell.onFeatureEnabledChanged = { [weak self] isEnabled in
            self?.multipleVotesFeature.isEnabled = isEnabled
            self?.collectionView.reloadItems(at: [indexPath])
        }
        return cell
    }

    // MARK: - Update Content

    override open func updateContent() {
        super.updateContent()

        validatePollOptions()
        createPollButton.isEnabled = canCreatePoll
    }

    /// Validates if the poll options contain any errors.
    open func validatePollOptions() {
        optionsErrorIndices = [:]
        options.enumerated().forEach { offset, option in
            guard let optionsSectionIndex = sections.firstIndex(of: .options) else { return }
            let indexPath = IndexPath(item: offset, section: optionsSectionIndex)
            let cell = collectionView.cellForItem(at: indexPath) as? PollCreationOptionCell
            var otherOptions = options
            otherOptions.remove(at: offset)
            if !option.isEmpty && otherOptions.contains(where: { $0 == option }) {
                optionsErrorIndices[offset] = "This is already an option"
            }
            cell?.content?.errorText = optionsErrorIndices[offset]
        }
    }

    // MARK: - Presentation Delegate

    open func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        !hasChanges
    }

    open func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        showDismissConfirmation()
    }

    // MARK: - Actions

    /// The cancel button was tapped.
    @objc open func cancelPoll() {
        if hasChanges {
            showDismissConfirmation()
            return
        }
        dismiss(animated: true)
    }

    /// Creates the poll with the current configuration.
    @objc open func createPoll() {
        channelController.createPoll(
            name: name,
            allowAnswers: commentsFeature.isEnabled,
            allowUserSuggestedOptions: suggestionsFeature.isEnabled,
            description: nil,
            enforceUniqueVote: !multipleVotesFeature.isEnabled,
            maxVotesAllowed: multipleVotesFeature.config.maxVotes,
            votingVisibility: anonymousFeature.isEnabled ? .anonymous : .public,
            options: options
                .filter { !$0.isEmpty }
                .map { PollOption(text: $0) },
            extraData: nil
        ) { [weak self] result in
            self?.handleCreatePollResponse(result: result)
        }
    }

    /// Shows an alert for the user to confirm it wants to discard his changes.
    open func showDismissConfirmation() {
        let alert = UIAlertController(
            title: nil,
            message: "Are you sure you want to discard your poll?",
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "Discard Changes", style: .destructive, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    /// Handles the poll creation response.
    open func handleCreatePollResponse(result: Result<MessageId, Error>) {
        switch result {
        case .success:
            dismiss(animated: true)
        case .failure:
            dismiss(animated: true)
        }
    }

    /// Manages the dragging and sorting of the collection view cells.
    @objc open func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let targetIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                return
            }
            collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            var location = gesture.location(in: collectionView)
            location.x = collectionView.center.x
            collectionView.updateInteractiveMovementTargetPosition(location)
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
}
