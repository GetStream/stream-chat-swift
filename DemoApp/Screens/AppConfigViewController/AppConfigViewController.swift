//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
    /// A Boolean value to define if an additional message debugger action will be added.
    var isMessageDebuggerEnabled: Bool
    /// Set this value to define if we should mimic token refresh scenarios.
    var tokenRefreshDetails: TokenRefreshDetails?
    /// A Boolean value that determines if a connection banner UI should be shown.
    var shouldShowConnectionBanner: Bool
    /// A Boolean value to define if the premium member feature is enabled. This is to test custom member data.
    var isPremiumMemberFeatureEnabled: Bool
    /// A Boolean value to define if the reminders feature is enabled.
    var isRemindersEnabled: Bool
    /// A Boolean value to define if the poll should be deleted when the message is deleted.
    var shouldDeletePollOnMessageDeletion: Bool

    /// The details to generate expirable tokens in the demo app.
    struct TokenRefreshDetails {
        /// The app secret from the dashboard.
        let appSecret: String
        /// The duration in seconds until the token is expired.
        let expirationDuration: TimeInterval
        /// In order to test token refresh fails, we can set a value of how
        /// many token refresh will fail before a successful one.
        let numberOfFailures: Int
    }
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
            isMessageDebuggerEnabled: false,
            tokenRefreshDetails: nil,
            shouldShowConnectionBanner: false,
            isPremiumMemberFeatureEnabled: false,
            isRemindersEnabled: true,
            shouldDeletePollOnMessageDeletion: false
        )

        if StreamRuntimeCheck.isStreamInternalConfiguration {
            demoAppConfig.isAtlantisEnabled = true
            demoAppConfig.isMessageDebuggerEnabled = true
            demoAppConfig.isHardDeleteEnabled = true
            demoAppConfig.shouldShowConnectionBanner = true
            demoAppConfig.isPremiumMemberFeatureEnabled = true
            demoAppConfig.isRemindersEnabled = true
            demoAppConfig.shouldDeletePollOnMessageDeletion = true
            StreamRuntimeCheck.assertionsEnabled = true
        }
    }
}

class UserConfig {
    var isInvisible = false
    var language: TranslationLanguage?
    var typingIndicatorsEnabled: Bool?
    var readReceiptsEnabled: Bool?

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
        case environment
        case pushConfiguration

        var description: String {
            switch self {
            case .environment:
                return "App Key"
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
        case tokenRefreshDetails
        case shouldShowConnectionBanner
        case isPremiumMemberFeatureEnabled
        case isRemindersEnabled
    }

    enum ComponentsConfigOption: String, CaseIterable {
        case isUniqueReactionsEnabled
        case isReactionPushEmojisEnabled
        case shouldMessagesStartAtTheTop
        case shouldAnimateJumpToMessageWhenOpeningChannel
        case shouldJumpToUnreadWhenOpeningChannel
        case threadRepliesStartFromOldest
        case threadRendersParentMessageEnabled
        case isVoiceRecordingEnabled
        case isVoiceRecordingConfirmationRequiredEnabled
        case channelListSearchStrategy
        case isUnreadMessageSeparatorEnabled
        case isJumpToUnreadEnabled
        case mentionAllAppUsers
        case isBlockingUsersEnabled
        case isMessageListAnimationsEnabled
        case isDownloadFileAttachmentsEnabled
    }

    enum ChatClientConfigOption: String, CaseIterable {
        case baseURL
        case isLocalStorageEnabled
        case staysConnectedInBackground
        case reconnectionTimeout
        case shouldShowShadowedMessages
        case deletedMessagesVisibility
        case isChannelAutomaticFilteringEnabled
    }

    enum UserConfigOption: String, CaseIterable {
        case isInvisible
        case language
        case typingIndicatorsEnabled
        case readReceiptsEnabled
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
        case let .info(options):
            didSelectInfoOptionsCell(cell, at: indexPath, options: options)
        case let .components(options):
            didSelectComponentsOptionsCell(cell, at: indexPath, options: options)
        case let .chatClient(options):
            didSelectChatClientOptionsCell(cell, at: indexPath, options: options)
        case let .user(options):
            didSelectUserOptionsCell(cell, at: indexPath, options: options)
        case let .demoApp(options):
            didSelectDemoAppOptionsCell(cell, at: indexPath, options: options)
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
        switch option {
        case .environment:
            cell.accessoryType = .disclosureIndicator
            cell.detailTextLabel?.text = apiKeyString
        case .pushConfiguration:
            break
        }
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
        case .tokenRefreshDetails:
            if let tokenRefreshDuration = demoAppConfig.tokenRefreshDetails?.expirationDuration {
                cell.detailTextLabel?.text = "Duration before expired: \(tokenRefreshDuration)s"
            } else {
                cell.detailTextLabel?.text = "Disabled"
            }
            cell.accessoryType = .none
        case .shouldShowConnectionBanner:
            cell.accessoryView = makeSwitchButton(demoAppConfig.shouldShowConnectionBanner) { [weak self] newValue in
                self?.demoAppConfig.shouldShowConnectionBanner = newValue
            }
        case .isPremiumMemberFeatureEnabled:
            cell.accessoryView = makeSwitchButton(demoAppConfig.isPremiumMemberFeatureEnabled) { [weak self] newValue in
                self?.demoAppConfig.isPremiumMemberFeatureEnabled = newValue
            }
        case .isRemindersEnabled:
            cell.accessoryView = makeSwitchButton(demoAppConfig.isRemindersEnabled) { [weak self] newValue in
                self?.demoAppConfig.isRemindersEnabled = newValue
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
        case .baseURL:
            cell.detailTextLabel?.text = chatClientConfig.baseURL.description
            cell.accessoryType = .disclosureIndicator
        case .isLocalStorageEnabled:
            cell.accessoryView = makeSwitchButton(chatClientConfig.isLocalStorageEnabled) { [weak self] newValue in
                self?.chatClientConfig.isLocalStorageEnabled = newValue
            }
        case .staysConnectedInBackground:
            cell.accessoryView = makeSwitchButton(chatClientConfig.staysConnectedInBackground) { [weak self] newValue in
                self?.chatClientConfig.staysConnectedInBackground = newValue
            }
        case .reconnectionTimeout:
            cell.detailTextLabel?.text = chatClientConfig.reconnectionTimeout.map { "\($0)" } ?? "None"
            cell.accessoryType = .disclosureIndicator
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
        case .baseURL:
            showBaseURLInputAlert()
        case .deletedMessagesVisibility:
            pushDeletedMessagesVisibilitySelectorVC()
        case .reconnectionTimeout:
            pushReconnectionTimeoutSelectorVC()
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
        case .readReceiptsEnabled:
            cell.accessoryView = makeSwitchButton(UserConfig.shared.readReceiptsEnabled ?? true) { newValue in
                UserConfig.shared.readReceiptsEnabled = newValue
            }
        case .typingIndicatorsEnabled:
            cell.accessoryView = makeSwitchButton(UserConfig.shared.typingIndicatorsEnabled ?? true) { newValue in
                UserConfig.shared.typingIndicatorsEnabled = newValue
            }
        case .language:
            cell.detailTextLabel?.text = UserConfig.shared.language?.languageCode
            cell.accessoryType = .disclosureIndicator
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
        case .isReactionPushEmojisEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.isReactionPushEmojisEnabled) { newValue in
                Components.default.isReactionPushEmojisEnabled = newValue
            }
        case .shouldMessagesStartAtTheTop:
            cell.accessoryView = makeSwitchButton(Components.default.shouldMessagesStartAtTheTop) { newValue in
                Components.default.shouldMessagesStartAtTheTop = newValue
            }
        case .shouldAnimateJumpToMessageWhenOpeningChannel:
            cell.accessoryView = makeSwitchButton(Components.default.shouldAnimateJumpToMessageWhenOpeningChannel) { newValue in
                Components.default.shouldAnimateJumpToMessageWhenOpeningChannel = newValue
            }
        case .shouldJumpToUnreadWhenOpeningChannel:
            cell.accessoryView = makeSwitchButton(Components.default.shouldJumpToUnreadWhenOpeningChannel) { newValue in
                Components.default.shouldJumpToUnreadWhenOpeningChannel = newValue
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
        case .mentionAllAppUsers:
            cell.accessoryView = makeSwitchButton(Components.default.mentionAllAppUsers) { newValue in
                Components.default.mentionAllAppUsers = newValue
            }
        case .isBlockingUsersEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.isBlockingUsersEnabled) { newValue in
                Components.default.isBlockingUsersEnabled = newValue
            }
        case .isMessageListAnimationsEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.isMessageListAnimationsEnabled) { newValue in
                Components.default.isMessageListAnimationsEnabled = newValue
            }
        case .isDownloadFileAttachmentsEnabled:
            cell.accessoryView = makeSwitchButton(Components.default.isDownloadFileAttachmentsEnabled) { newValue in
                Components.default.isDownloadFileAttachmentsEnabled = newValue
            }
        }
    }

    private func didSelectInfoOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [DemoAppInfoOption]
    ) {
        let option = options[indexPath.row]
        switch option {
        case .environment:
            pushEnvironmentSelectorVC()
        case .pushConfiguration:
            break
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

    private func didSelectUserOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [UserConfigOption]
    ) {
        let option = options[indexPath.row]
        switch option {
        case .language:
            pushUserLanguageSelectorVC()
        default:
            break
        }
    }

    private func didSelectDemoAppOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [DemoAppConfigOption]
    ) {
        let option = options[indexPath.row]
        switch option {
        case .tokenRefreshDetails:
            showTokenDetailsAlert()
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

    private func pushUserLanguageSelectorVC() {
        let selectorViewController = OptionsSelectorViewController(
            options: TranslationLanguage.allCases,
            initialSelectedOptions: [nil],
            allowsMultipleSelection: false,
            optionFormatter: { option in
                option?.languageCode ?? "nil"
            }
        )
        selectorViewController.didChangeSelectedOptions = { [weak self] options in
            guard let selectedOption = options.first else { return }
            UserConfig.shared.language = selectedOption
            self?.tableView.reloadData()
        }

        navigationController?.pushViewController(selectorViewController, animated: true)
    }

    private func pushReconnectionTimeoutSelectorVC() {
        let selectorViewController = OptionsSelectorViewController<TimeInterval?>(
            options: [nil, 15.0, 30.0, 45.0, 60.0],
            initialSelectedOptions: [chatClientConfig.reconnectionTimeout],
            allowsMultipleSelection: false,
            optionFormatter: { option in
                option.map { "\($0)" } ?? "None"
            }
        )
        selectorViewController.didChangeSelectedOptions = { [weak self] options in
            guard let selectedOption = options.first else { return }
            self?.chatClientConfig.reconnectionTimeout = selectedOption
            self?.tableView.reloadData()
        }

        navigationController?.pushViewController(selectorViewController, animated: true)
    }

    private func showBaseURLInputAlert() {
        let alert = UIAlertController(
            title: "Base URL",
            message: "Input the base URL for the Chat Client.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Base URL"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.text = self.chatClientConfig.baseURL.description
            textField.textContentType = .URL
        }

        alert.addAction(.init(title: "Set", style: .default, handler: { _ in
            guard let urlString = alert.textFields?.first?.text,
                  let url = URL(string: urlString)
            else {
                return
            }
            self.chatClientConfig.baseURL = .init(url: url)
            self.tableView.reloadData()
        }))

        alert.addAction(.init(title: "Cancel", style: .destructive, handler: nil))

        present(alert, animated: true, completion: nil)
    }

    private func showTokenDetailsAlert() {
        let alert = UIAlertController(
            title: "Token Refreshing",
            message: "Input the app secret from Stream's Dashboard and the desired duration.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "App Secret"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            if let appSecret = self.demoAppConfig.tokenRefreshDetails?.appSecret {
                textField.text = appSecret
            }
        }
        alert.addTextField { textField in
            textField.placeholder = "Expiration duration (Seconds)"
            textField.keyboardType = .numberPad
            if let duration = self.demoAppConfig.tokenRefreshDetails?.expirationDuration {
                textField.text = "\(duration)"
            }
        }
        alert.addTextField { textField in
            textField.placeholder = "Number of refresh fails"
            textField.keyboardType = .numberPad
            if let numberOfRefreshes = self.demoAppConfig.tokenRefreshDetails?.numberOfFailures {
                textField.text = "\(numberOfRefreshes)"
            }
        }

        alert.addAction(.init(title: "Enable", style: .default, handler: { _ in
            guard let appSecret = alert.textFields?[0].text else { return }
            guard let duration = alert.textFields?[1].text else { return }
            guard let numberOfFailures = alert.textFields?[2].text else { return }
            self.demoAppConfig.tokenRefreshDetails = .init(
                appSecret: appSecret,
                expirationDuration: TimeInterval(duration) ?? 60,
                numberOfFailures: Int(numberOfFailures) ?? 0
            )
        }))

        alert.addAction(.init(title: "Disable", style: .destructive, handler: { _ in
            self.demoAppConfig.tokenRefreshDetails = nil
        }))

        present(alert, animated: true, completion: nil)
    }

    private func pushEnvironmentSelectorVC() {
        let selectorViewController = OptionsSelectorViewController<DemoApiKeys>(
            options: [.frankfurtC1, .frankfurtC2, .usEastC6],
            initialSelectedOptions: [DemoApiKeys(rawValue: apiKeyString)],
            allowsMultipleSelection: false,
            optionFormatter: { option in
                var optionName = option.rawValue
                if let appName = option.appName {
                    optionName += " (\(appName))"
                }
                return optionName
            }
        )
        selectorViewController.didChangeSelectedOptions = { [weak self] options in
            guard let selectedOption = options.first else { return }
            apiKeyString = selectedOption.rawValue
            StreamChatWrapper.replaceSharedInstance(apiKeyString: apiKeyString)
            if let baseURL = selectedOption.customBaseURL {
                self?.chatClientConfig.baseURL = .init(url: baseURL)
            }
            self?.tableView.reloadData()
        }

        navigationController?.pushViewController(selectorViewController, animated: true)
    }
}
