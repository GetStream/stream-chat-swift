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
        public var error: Error?

        public init(name: String, error: Error? = nil) {
            self.name = name
            self.error = error
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
    public var name: String = ""

    /// The available options of the poll.
    public var options: [Option] = [Option(name: "")]

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
    public var maximumVotesText: String = ""

    /// The error in case the maximum votes is not valid.
    public var maximumVotesErrorText: String?

    // MARK: - Views

    /// The table view responsible to display the poll creation form.
    open private(set) lazy var tableView = UITableView(frame: .zero, style: .grouped)
        .withoutAutoresizingMaskConstraints

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
        tableView.register(PollCreationTextFieldCell.self)
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

    open func pollNameCell(at indexPath: IndexPath) -> PollCreationTextFieldCell {
        let cell = tableView.dequeueReusableCell(with: PollCreationTextFieldCell.self, for: indexPath)
        cell.isReorderingSupported = false
        cell.content = .init(
            initialText: name,
            placeholder: "Ask a question",
            errorText: nil
        )
        cell.textFieldView.onTextChanged = { [weak self] _, newValue in
            self?.name = newValue
        }
        return cell
    }

    open func pollOptionCell(at indexPath: IndexPath) -> PollCreationTextFieldCell {
        let cell = tableView.dequeueReusableCell(with: PollCreationTextFieldCell.self, for: indexPath)
        let option = options[indexPath.item]
        cell.content = .init(
            initialText: option.name,
            placeholder: "Add an option",
            errorText: nil
        )
        cell.textFieldView.inputTextField.text = option.name
        cell.textFieldView.onTextChanged = { [weak self] oldValue, newValue in
            self?.options[indexPath.item] = .init(name: newValue)
            let numberOfOptions = self?.options.count ?? 0
            let isLastItem = indexPath.item == numberOfOptions - 1
            if isLastItem && !newValue.isEmpty {
                self?.options.append(.empty)
                let newIndexPath = IndexPath(item: indexPath.item + 1, section: indexPath.section)
                self?.tableView.insertRows(at: [newIndexPath], with: .bottom)
            }
            if oldValue.isEmpty && newValue.isEmpty && !isLastItem {
                self?.options.remove(at: indexPath.item)
                self?.tableView.reloadData()
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

    // MARK: - Actions

    /// Creates the poll with the current configuration.
    open func createPoll() {
        channelController.createPoll(
            name: name,
            allowAnswers: commentsFeature.isEnabled,
            allowUserSuggestedOptions: suggestionsFeature.isEnabled,
            description: nil,
            enforceUniqueVote: !multipleVotesFeature.isEnabled,
            maxVotesAllowed: multipleVotesFeature.config.maxVotes,
            votingVisibility: anonymousFeature.isEnabled ? .anonymous : .public,
            options: options.map { PollOption(text: $0.name) },
            extraData: nil
        ) { result in
            print(result)
        }
    }
}
