//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// The Demo App Configuration.
struct DemoAppConfig {
    /// A Boolean value to define if an additional hard delete message action will be added.
    var isHardDeleteEnabled: Bool
    /// A Boolean value to define if Atlantis will be started to proxy HTTP and WebSocket calls.
    var isAtlantisEnabled: Bool
    /// A Boolean value to define if we should mimic token refresh scenarios.
    var isTokenRefreshEnabled: Bool
    /// A Boolean value to define if an additional message debugger action will be added.
    var isMessageDebuggerEnabled: Bool
    /// A Boolean value to define if channel pinning example is enabled.
    var isChannelPinningEnabled: Bool
}

class AppConfig {
    /// The Demo App Configuration.
    var demoAppConfig: DemoAppConfig

    static var shared = AppConfig()

    private init() {
        // Default DemoAppConfig
        demoAppConfig = DemoAppConfig(
            isHardDeleteEnabled: false,
            isAtlantisEnabled: false,
            isTokenRefreshEnabled: false,
            isMessageDebuggerEnabled: false,
            isChannelPinningEnabled: false
        )
    }
}

class UserConfig {
    var isInvisible = false

    static var shared = UserConfig()

    private init() {}
}

class AppConfigViewController: UITableViewController {
    var demoAppConfig: DemoAppConfig {
        get { AppConfig.shared.demoAppConfig }
        set {
            AppConfig.shared.demoAppConfig = newValue
            tableView.reloadData()
        }
    }

    var chatClientConfig: ChatClientConfig {
        get { StreamChatWrapper.shared.config }
        set {
            StreamChatWrapper.shared.config = newValue
            tableView.reloadData()
        }
    }

    var channelListSearchStrategy: ChannelListSearchStrategy? {
        get {
            Components.default.channelListSearchStrategy
        }
        set {
            Components.default.channelListSearchStrategy = newValue
        }
    }

    init() {
        super.init(style: .grouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum ConfigOption {
        case info([DemoAppInfoOption])
        case demoApp([DemoAppConfigOption])
        case components([ComponentsConfigOption])
        case chatClient([ChatClientConfigOption])
        case user([UserConfigOption])

        var numberOfOptions: Int {
            switch self {
            case let .info(options):
                return options.count
            case let .demoApp(options):
                return options.count
            case let .components(options):
                return options.count
            case let .chatClient(options):
                return options.count
            case let .user(options):
                return options.count
            }
        }

        var sectionTitle: String {
            switch self {
            case .demoApp:
                return "Demo App Configuration"
            case .components:
                return "Components Configuration"
            case .chatClient:
                return "Chat Client Configuration"
            case .info:
                return "General Info"
            case .user:
                return "User Info"
            }
        }
    }

    enum DemoAppInfoOption: CustomStringConvertible, CaseIterable {
        case pushConfiguration

        var description: String {
            switch self {
            case .pushConfiguration:
                let configuration = Bundle.pushProviderName ?? "Not set"
                return "Push Configuration: \(configuration)"
            }
        }
    }

    enum DemoAppConfigOption: String, CaseIterable {
        case isHardDeleteEnabled
        case isAtlantisEnabled
        case isMessageDebuggerEnabled
        case isChannelPinningEnabled
    }

    enum ComponentsConfigOption: String, CaseIterable {
        case isUniqueReactionsEnabled
        case shouldMessagesStartAtTheTop
        case shouldAnimateJumpToMessageWhenOpeningChannel
        case threadRepliesStartFromOldest
        case threadRendersParentMessageEnabled
        case isVoiceRecordingEnabled
        case isVoiceRecordingConfirmationRequiredEnabled
        case channelListSearchStrategy
        case isUnreadMessageSeparatorEnabled
        case isJumpToUnreadEnabled
    }

    enum ChatClientConfigOption: String, CaseIterable {
        case isLocalStorageEnabled
        case staysConnectedInBackground
        case shouldShowShadowedMessages
        case deletedMessagesVisibility
        case isChannelAutomaticFilteringEnabled
    }

    enum UserConfigOption: String, CaseIterable {
        case isInvisible
    }

    let options: [ConfigOption] = [
        .info(DemoAppInfoOption.allCases),
        .demoApp(DemoAppConfigOption.allCases),
        .components(ComponentsConfigOption.allCases),
        .chatClient(ChatClientConfigOption.allCases),
        .user(UserConfigOption.allCases)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Configuration"
    }

    // MARK: Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        options.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        options[section].numberOfOptions
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        options[section].sectionTitle
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)

        switch options[indexPath.section] {
        case let .info(options):
            configureDemoAppInfoCell(cell, at: indexPath, options: options)

        case let .demoApp(options):
            configureDemoAppOptionsCell(cell, at: indexPath, options: options)

        case let .components(options):
            configureComponentsOptionsCell(cell, at: indexPath, options: options)

        case let .chatClient(options):
            configureChatClientOptionsCell(cell, at: indexPath, options: options)

        case let .user(options):
            configureUserOptionsCell(cell, at: indexPath, options: options)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        switch options[indexPath.section] {
        case .info, .user, .demoApp:
            break

        case let .components(options):
            didSelectComponentsOptionsCell(cell, at: indexPath, options: options)

        case let .chatClient(options):
            didSelectChatClientOptionsCell(cell, at: indexPath, options: options)
        }
    }

    // MAKR: - Demo App Info

    private func configureDemoAppInfoCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [DemoAppInfoOption]
    ) {
        let option = options[indexPath.row]
        cell.textLabel?.text = option.description
    }

    // MARK: - Demo App Options

    private func configureDemoAppOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [DemoAppConfigOption]
    ) {
        let option = options[indexPath.row]
        cell.textLabel?.text = option.rawValue

        switch option {
        case .isHardDeleteEnabled:
            cell.accessoryView = makeSwitchButton(demoAppConfig.isHardDeleteEnabled) { [weak self] newValue in
                self?.demoAppConfig.isHardDeleteEnabled = newValue
            }
        case .isAtlantisEnabled:
            cell.accessoryView = makeSwitchButton(demoAppConfig.isAtlantisEnabled) { [weak self] newValue in
                self?.demoAppConfig.isAtlantisEnabled = newValue
            }
        case .isMessageDebuggerEnabled:
            cell.accessoryView = makeSwitchButton(demoAppConfig.isMessageDebuggerEnabled) { [weak self] newValue in
                self?.demoAppConfig.isMessageDebuggerEnabled = newValue
            }
        case .isChannelPinningEnabled:
            cell.accessoryView = makeSwitchButton(demoAppConfig.isChannelPinningEnabled) { [weak self] newValue in
                self?.demoAppConfig.isChannelPinningEnabled = newValue
            }
        }
    }

    // MARK: - Chat Client Options

    private func configureChatClientOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [ChatClientConfigOption]
    ) {
        let option = options[indexPath.row]
        cell.textLabel?.text = option.rawValue

        switch option {
        case .isLocalStorageEnabled:
            cell.accessoryView = makeSwitchButton(chatClientConfig.isLocalStorageEnabled) { [weak self] newValue in
                self?.chatClientConfig.isLocalStorageEnabled = newValue
            }
        case .staysConnectedInBackground:
            cell.accessoryView = makeSwitchButton(chatClientConfig.staysConnectedInBackground) { [weak self] newValue in
                self?.chatClientConfig.staysConnectedInBackground = newValue
            }
        case .shouldShowShadowedMessages:
            cell.accessoryView = makeSwitchButton(chatClientConfig.shouldShowShadowedMessages) { [weak self] newValue in
                self?.chatClientConfig.shouldShowShadowedMessages = newValue
            }
        case .deletedMessagesVisibility:
            cell.detailTextLabel?.text = chatClientConfig.deletedMessagesVisibility.description
            cell.accessoryType = .disclosureIndicator

        case .isChannelAutomaticFilteringEnabled:
            cell.accessoryView = makeSwitchButton(chatClientConfig.isChannelAutomaticFilteringEnabled) { [weak self] newValue in
                self?.chatClientConfig.isChannelAutomaticFilteringEnabled = newValue
            }
        }
    }

    private func didSelectChatClientOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [ChatClientConfigOption]
    ) {
        let option = options[indexPath.row]
        switch option {
        case .deletedMessagesVisibility:
            pushDeletedMessagesVisibilitySelectorVC()
        default:
            break
        }
    }

    // MARK: User Options

    private func configureUserOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [UserConfigOption]
    ) {
        let option = options[indexPath.row]
        cell.textLabel?.text = option.rawValue

        switch option {
        case .isInvisible:
            cell.accessoryView = makeSwitchButton(UserConfig.shared.isInvisible) { newValue in
                UserConfig.shared.isInvisible = newValue
            }
        }
    }

    // MARK: Components Options

    private func configureComponentsOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [ComponentsConfigOption]
    ) {
        let option = options[indexPath.row]
        cell.textLabel?.text = option.rawValue

        switch option {
        case .isUniqueReactionsEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.isUniqueReactionsEnabled) { newValue in
                Components.default.isUniqueReactionsEnabled = newValue
            }
        case .shouldMessagesStartAtTheTop:
            cell.accessoryView = makeSwitchButton(Components.default.shouldMessagesStartAtTheTop) { newValue in
                Components.default.shouldMessagesStartAtTheTop = newValue
            }
        case .shouldAnimateJumpToMessageWhenOpeningChannel:
            cell.accessoryView = makeSwitchButton(Components.default.shouldAnimateJumpToMessageWhenOpeningChannel) { newValue in
                Components.default.shouldAnimateJumpToMessageWhenOpeningChannel = newValue
            }
        case .threadRepliesStartFromOldest:
            cell.accessoryView = makeSwitchButton(Components.default.threadRepliesStartFromOldest) { newValue in
                Components.default.threadRepliesStartFromOldest = newValue
            }
        case .threadRendersParentMessageEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.threadRendersParentMessageEnabled) { newValue in
                Components.default.threadRendersParentMessageEnabled = newValue
            }
        case .isVoiceRecordingEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.isVoiceRecordingEnabled) { newValue in
                Components.default.isVoiceRecordingEnabled = newValue
            }
        case .isVoiceRecordingConfirmationRequiredEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.isVoiceRecordingConfirmationRequiredEnabled) { newValue in
                Components.default.isVoiceRecordingConfirmationRequiredEnabled = newValue
            }
        case .channelListSearchStrategy:
            cell.detailTextLabel?.text = channelListSearchStrategy?.name ?? "none"
            cell.accessoryType = .disclosureIndicator
        case .isUnreadMessageSeparatorEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.isUnreadMessagesSeparatorEnabled) { newValue in
                Components.default.isUnreadMessagesSeparatorEnabled = newValue
            }
        case .isJumpToUnreadEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.isJumpToUnreadEnabled) { newValue in
                Components.default.isJumpToUnreadEnabled = newValue
            }
        }
    }

    private func didSelectComponentsOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [ComponentsConfigOption]
    ) {
        let option = options[indexPath.row]
        switch option {
        case .channelListSearchStrategy:
            pushChannelListSearchStrategySelectorVC()
        default:
            break
        }
    }

    // MARK: - Helpers

    private func makeSwitchButton(_ initialValue: Bool, _ didChangeValue: @escaping (Bool) -> Void) -> SwitchButton {
        let switchButton = SwitchButton()
        switchButton.isOn = initialValue
        switchButton.didChangeValue = didChangeValue
        return switchButton
    }

    private func pushDeletedMessagesVisibilitySelectorVC() {
        let selectorViewController = OptionsSelectorViewController(
            options: [.alwaysHidden, .alwaysVisible, .visibleForCurrentUser],
            initialSelectedOptions: [chatClientConfig.deletedMessagesVisibility],
            allowsMultipleSelection: false
        )
        selectorViewController.didChangeSelectedOptions = { [weak self] options in
            guard let selectedOption = options.first else { return }
            self?.chatClientConfig.deletedMessagesVisibility = selectedOption
        }

        navigationController?.pushViewController(selectorViewController, animated: true)
    }

    private func pushChannelListSearchStrategySelectorVC() {
        let selectorViewController = OptionsSelectorViewController(
            options: [ChannelListSearchStrategy.channels.name, ChannelListSearchStrategy.messages.name, nil],
            initialSelectedOptions: [channelListSearchStrategy?.name],
            allowsMultipleSelection: false,
            optionFormatter: { option in
                option ?? "none"
            }
        )
        selectorViewController.didChangeSelectedOptions = { [weak self] options in
            guard let selectedOption = options.first else { return }
            if selectedOption == ChannelListSearchStrategy.channels.name {
                self?.channelListSearchStrategy = ChannelListSearchStrategy.channels
            } else if selectedOption == ChannelListSearchStrategy.messages.name {
                self?.channelListSearchStrategy = ChannelListSearchStrategy.messages
            } else {
                self?.channelListSearchStrategy = nil
            }
            self?.tableView.reloadData()
        }

        navigationController?.pushViewController(selectorViewController, animated: true)
    }
}
