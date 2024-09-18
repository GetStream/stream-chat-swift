//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The sections for the poll creation view.
public struct PollCreationSection: RawRepresentable, Equatable {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The section to edit the name of the poll.
    public static var name = Self(rawValue: 0)
    /// The section to provide the options of the poll.
    public static var options = Self(rawValue: 1)
    /// THe section to enable or disable the poll features.
    public static var features = Self(rawValue: 2)
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

    /// The sections of the poll creation form.
    public var sections: [PollCreationSection] = [
        .name,
        .options,
        .features
    ]

    /// The name of the poll.
    public var name: String = ""

    /// The available options of the poll.
    public var options: [String] = [""]

    /// The multiple votes feature configuration.
    public var allowMultipleVotesFeature = MultipleVotesPollFeature(
        name: "Multiple votes",
        isEnabled: false,
        config: .disabled
    )

    /// The anonymous feature configuration.
    public var isAnonymousFeature = BasicPollFeature(
        name: "Anonymous poll",
        isEnabled: false
    )

    /// The allow suggestions feature configuration.
    public var allowSuggestionsFeature = BasicPollFeature(
        name: "Suggest an option",
        isEnabled: false
    )

    /// The allow comments feature configuration.
    public var allowCommentsFeature = BasicPollFeature(
        name: "Add a comment",
        isEnabled: false
    )

    /// The features supported to be enabled in the poll.
    open var pollFeatures: [PollFeature] {
        [
            allowMultipleVotesFeature,
            isAnonymousFeature,
            allowSuggestionsFeature,
            allowCommentsFeature
        ]
    }

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

        tableView.register(PollCreationTextFieldCell.self)
        tableView.register(PollCreationFeatureCell.self)
        tableView.register(PollCreationMultipleVotesFeatureCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isEditing = true
        tableView.tableHeaderView = UIView()
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        title = "Create Poll"
        tableView.separatorStyle = .none
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
        let section = sections[indexPath.section]
        switch section {
        case .name:
            let cell = tableView.dequeueReusableCell(with: PollCreationTextFieldCell.self, for: indexPath)
            cell.content = .init(
                initialText: name,
                placeholder: "Ask a question",
                errorText: nil
            )
            cell.textFieldView.onTextChanged = { [weak self] _, newValue in
                self?.name = newValue
            }
            return cell
        case .options:
            let cell = PollCreationTextFieldCell()
            let option = options[indexPath.item]
            cell.content = .init(
                initialText: option,
                placeholder: "Add an option",
                errorText: nil
            )
            cell.textFieldView.onTextChanged = { [weak self] oldValue, newValue in
                self?.options[indexPath.item] = newValue
                let numberOfOptions = self?.options.count ?? 0
                let isLastItem = indexPath.item == numberOfOptions - 1
                if isLastItem && !newValue.isEmpty {
                    self?.options.append("")
                    let newIndexPath = IndexPath(item: indexPath.item + 1, section: section.rawValue)
                    tableView.insertRows(at: [newIndexPath], with: .bottom)
                }
                if oldValue.isEmpty && newValue.isEmpty && !isLastItem {
                    self?.options.remove(at: indexPath.item)
                    self?.tableView.reloadData()
                }
            }
            return cell
        case .features:
            let feature = pollFeatures[indexPath.item]
            if let multipleVotesFeature = feature as? MultipleVotesPollFeature {
                let cell = tableView.dequeueReusableCell(
                    with: PollCreationMultipleVotesFeatureCell.self,
                    for: indexPath
                )
                cell.featureSwitchView.featureNameLabel.text = feature.name
                cell.featureSwitchView.switchView.isOn = feature.isEnabled
                cell.maximumVotesSwitchView.isHidden = !feature.isEnabled
                cell.featureSwitchView.onValueChange = { isOn in
                    self.allowMultipleVotesFeature.isEnabled = isOn
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
                cell.maximumVotesSwitchView.textFieldView.content = .init(
                    initialText: multipleVotesFeature.config.maxVotes.map(String.init),
                    placeholder: "Maximum votes per person",
                    errorText: nil
                )
                cell.maximumVotesSwitchView.textFieldView.onTextChanged = { _, newValue in
                    if newValue.isEmpty { cell.maximumVotesSwitchView.textFieldView.content?.errorText = nil
                        return
                    }

                    guard let value = Int(newValue) else {
                        cell.maximumVotesSwitchView.textFieldView.content?.errorText = "Error"
                        return
                    }
                    cell.maximumVotesSwitchView.textFieldView.content?.errorText = nil
                    self.allowMultipleVotesFeature.config.maxVotes = value
                }
                return cell
            }
            let cell = tableView.dequeueReusableCell(
                with: PollCreationFeatureCell.self,
                for: indexPath
            )
            cell.content = .init(featureName: feature.name)
            return cell
        default:
            return UITableViewCell()
        }
    }

    open func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        let section = sections[indexPath.section]
        switch section {
        case .options:
            let option = options[indexPath.item]
            return !option.isEmpty
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

    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = sections[section]
        switch section {
        case .name:
            return "Question"
        case .options:
            return "Options"
        case .features:
            return nil
        default:
            return nil
        }
    }

    // MARK: - Actions

    /// Creates the poll with the current configuration.
    open func createPoll() {
        channelController.createPoll(
            name: name,
            allowAnswers: allowCommentsFeature.isEnabled,
            allowUserSuggestedOptions: allowSuggestionsFeature.isEnabled,
            description: nil,
            enforceUniqueVote: !allowMultipleVotesFeature.isEnabled,
            maxVotesAllowed: allowMultipleVotesFeature.config.maxVotes,
            votingVisibility: isAnonymousFeature.isEnabled ? .anonymous : .public,
            options: options.map { PollOption(text: $0) },
            extraData: nil
        ) { result in
            print(result)
        }
    }
}
