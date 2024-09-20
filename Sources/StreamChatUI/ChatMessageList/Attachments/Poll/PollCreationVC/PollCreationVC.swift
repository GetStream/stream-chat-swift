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

/// The view controller to create a poll in the given channel.
open class PollCreationVC:
    _ViewController,
    ThemeProvider,
    UITableViewDelegate,
    UITableViewDataSource {
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

    /// A poll option.
    public struct Option {
        public var name: String
        public var errorText: String?

        public init(name: String, errorText: String? = nil) {
            self.name = name
            self.errorText = errorText
        }

        public static var empty = Option(name: "")
    }

    /// The sections of the poll creation form.
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
    public var options: [Option] = [Option(name: "")] {
        didSet {
            updateContentIfNeeded()
        }
    }

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

    /// A boolean value indicating if there are no errors and it is possible to create the poll.
    open var canCreatePoll: Bool {
        name.isEmpty == false
            && maximumVotesErrorText == nil
            && options.filter { !$0.name.isEmpty }.count >= 2
            && options.first(where: { $0.errorText != nil }) == nil
    }

    // MARK: - Views

    /// The table view responsible to display the poll creation form.
    open private(set) lazy var tableView = UITableView(frame: .zero, style: .grouped)
        .withoutAutoresizingMaskConstraints

    /// The button to create the poll.
    open private(set) lazy var createPollButton = UIBarButtonItem(
        image: UIImage(systemName: "paperplane.fill")!,
        style: .plain,
        target: self,
        action: #selector(createPoll)
    )

    /// Component responsible for setting the correct offset when keyboard frame is changed.
    open lazy var keyboardHandler: KeyboardHandler = DefaultTableViewKeyboardHandler(
        tableView: self.tableView
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

        // TODO: Use Components
        tableView.register(PollCreationNameCell.self)
        tableView.register(PollCreationOptionCell.self)
        tableView.register(PollCreationFeatureCell.self)
        tableView.register(PollCreationMultipleVotesFeatureCell.self)
        tableView.register(PollCreationSectionHeaderView.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isEditing = true
        tableView.tableHeaderView = UIView()
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        title = "Create Poll"
        tableView.separatorStyle = .none
        tableView.backgroundColor = appearance.colorPalette.background
        tableView.sectionFooterHeight = 8

        navigationItem.rightBarButtonItems = [createPollButton]
    }

    override open func setUpLayout() {
        super.setUpLayout()

        view.embed(tableView)
    }

    // MARK: - UITableViewDelegate & UITableViewDataSource

    open func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

    open func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        .none
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let section = sections[indexPath.section]
        switch section {
        case .name:
            cell = pollNameCell(at: indexPath)
        case .options:
            cell = pollOptionCell(at: indexPath)
        case .features:
            let feature = pollFeatures[indexPath.item]
            switch feature {
            case .multipleVotes:
                cell = pollMultipleVotesFeatureCell(at: indexPath)
            case .anonymous:
                let basicFeatureCell = pollBasicFeatureCell(at: indexPath, feature: anonymousFeature)
                basicFeatureCell.onValueChange = { [weak self] newValue in
                    self?.anonymousFeature.isEnabled = newValue
                }
                cell = basicFeatureCell
            case .suggestions:
                let basicFeatureCell = pollBasicFeatureCell(at: indexPath, feature: suggestionsFeature)
                basicFeatureCell.onValueChange = { [weak self] newValue in
                    self?.suggestionsFeature.isEnabled = newValue
                }
                cell = basicFeatureCell
            case .comments:
                let basicFeatureCell = pollBasicFeatureCell(at: indexPath, feature: commentsFeature)
                basicFeatureCell.onValueChange = { [weak self] newValue in
                    self?.commentsFeature.isEnabled = newValue
                }
                cell = basicFeatureCell
            default:
                cell = UITableViewCell()
            }
        default:
            cell = UITableViewCell()
        }
        return cell
    }

    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section]
        switch section {
        case .options:
            let isAddNewOptionItem = indexPath.item == options.count - 1
            return !isAddNewOptionItem
        default:
            return false
        }
    }

    open func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = options[sourceIndexPath.row]
        options.remove(at: sourceIndexPath.row)
        options.insert(movedObject, at: destinationIndexPath.row)
        tableView.reloadData()
    }

    open func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        switch sections[proposedDestinationIndexPath.section] {
        case .options:
            if proposedDestinationIndexPath.item == options.count - 1 {
                return sourceIndexPath
            }
            return proposedDestinationIndexPath
        default:
            return sourceIndexPath
        }
    }

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooter(with: PollCreationSectionHeaderView.self)
        let section = sections[section]
        switch section {
        case .name:
            view.content = .init(title: "Question")
            return view
        case .options:
            view.content = .init(title: "Options")
            return view
        case .features:
            return nil
        default:
            return nil
        }
    }

    // MARK: - Cell Configuration

    open func pollNameCell(at indexPath: IndexPath) -> PollCreationNameCell {
        let cell = tableView.dequeueReusableCell(with: PollCreationNameCell.self, for: indexPath)
        cell.content = .init(
            placeholder: "Ask a question",
            errorText: nil
        )
        cell.setText(name)
        cell.onTextChanged = { [weak self] _, newValue in
            self?.name = newValue
        }
        return cell
    }

    open func pollOptionCell(at indexPath: IndexPath) -> PollCreationOptionCell {
        let cell = tableView.dequeueReusableCell(with: PollCreationOptionCell.self, for: indexPath)
        let option = options[indexPath.item]
        cell.content = .init(
            placeholder: "Add an option",
            errorText: option.errorText
        )
        cell.setText(option.name)
        cell.onTextChanged = { [weak self, weak tableView, weak cell] oldValue, newValue in
            guard let self = self else { return }
            guard let cell = cell else { return }
            guard let tableView = tableView else { return }
            guard indexPath.item < self.options.count else { return }

            var errorText: String?
            if !newValue.isEmpty, self.options.contains(where: { $0.name == newValue }) {
                errorText = "This is already an option"
            }

            cell.content?.errorText = errorText
            self.options[indexPath.item] = .init(name: newValue, errorText: errorText)

            let numberOfOptions = self.options.count
            let isLastItem = indexPath.item == numberOfOptions - 1
            if isLastItem && !newValue.isEmpty {
                self.options.append(.empty)
                let newIndexPath = IndexPath(item: indexPath.item + 1, section: indexPath.section)
                tableView.insertRows(at: [newIndexPath], with: .bottom)
            } else if oldValue.isEmpty && newValue.isEmpty && !isLastItem {
                self.options.remove(at: indexPath.item)
                tableView.reloadData()
            }
        }
        return cell
    }

    open func pollMultipleVotesFeatureCell(at indexPath: IndexPath) -> PollCreationMultipleVotesFeatureCell {
        let cell = tableView.dequeueReusableCell(
            with: PollCreationMultipleVotesFeatureCell.self,
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
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        return cell
    }

    open func pollBasicFeatureCell(at indexPath: IndexPath, feature: PollFeature) -> PollCreationFeatureCell {
        let cell = tableView.dequeueReusableCell(
            with: PollCreationFeatureCell.self,
            for: indexPath
        )
        cell.content = .init(featureName: feature.name)
        return cell
    }

    // MARK: - Update Content

    override open func updateContent() {
        super.updateContent()

        createPollButton.isEnabled = canCreatePoll
    }

    // MARK: - Actions

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
                .filter { !$0.name.isEmpty }
                .map { PollOption(text: $0.name) },
            extraData: nil
        ) { [weak self] result in
            self?.handleCreatePollResponse(result: result)
        }
    }

    open func handleCreatePollResponse(result: Result<MessageId, Error>) {
        switch result {
        case .success:
            dismiss(animated: true)
        case .failure:
            dismiss(animated: true)
        }
    }
}
