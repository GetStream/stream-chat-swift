//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
/// The Demo App Configuration.
struct DemoAppConfig {
    /// A Boolean value to define if an additional hard delete message action will be added.
    var isHardDeleteEnabled: Bool
    /// A Boolean value to define if Atlantis will be started to proxy HTTP and WebSocket calls.
    var isAtlantisEnabled: Bool
}

class AppConfig {
    /// The Demo App Configuration.
    var demoAppConfig: DemoAppConfig
    /// The StreamChat SDK Config.
    var chatClientConfig: ChatClientConfig

    static var shared = AppConfig()

    private init() {
        // Default DemoAppConfig
        demoAppConfig = DemoAppConfig(
            isHardDeleteEnabled: false,
            isAtlantisEnabled: false
        )

        // Default ChatClientConfig
        chatClientConfig = ChatClientConfig(apiKeyString: apiKeyString)
        chatClientConfig.shouldShowShadowedMessages = true
        chatClientConfig.applicationGroupIdentifier = applicationGroupIdentifier
        chatClientConfig.deletedMessagesVisibility = .visibleForCurrentUser
    }
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
        get { AppConfig.shared.chatClientConfig }
        set {
            AppConfig.shared.chatClientConfig = newValue
            tableView.reloadData()
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
        case demoApp([DemoAppConfigOption])
        case chatClient([ChatClientConfigOption])

        var numberOfOptions: Int {
            switch self {
            case let .demoApp(options):
                return options.count
            case let .chatClient(options):
                return options.count
            }
        }

        var sectionTitle: String {
            switch self {
            case .demoApp:
                return "Demo App Configuration"
            case .chatClient:
                return "Chat Client Configuration"
            }
        }
    }

    enum DemoAppConfigOption: String, CaseIterable {
        case isHardDeleteEnabled
        case isAtlantisEnabled
    }

    enum ChatClientConfigOption: String, CaseIterable {
        case isLocalStorageEnabled
        case shouldShowShadowedMessages
        case deletedMessagesVisibility
    }

    let options: [ConfigOption] = [
        .demoApp(DemoAppConfigOption.allCases),
        .chatClient(ChatClientConfigOption.allCases)
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
        case let .demoApp(options):
            configureDemoAppOptionsCell(cell, at: indexPath, options: options)

        case let .chatClient(options):
            configureChatClientOptionsCell(cell, at: indexPath, options: options)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }

        switch options[indexPath.section] {
        case let .demoApp(options):
            didSelectDemoAppOptionsCell(cell, at: indexPath, options: options)

        case let .chatClient(options):
            didSelectChatClientOptionsCell(cell, at: indexPath, options: options)
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
            cell.accessoryView = makeSwitchButton(demoAppConfig.isHardDeleteEnabled) { newValue in
                self.demoAppConfig.isHardDeleteEnabled = newValue
            }
        case .isAtlantisEnabled:
            cell.accessoryView = makeSwitchButton(demoAppConfig.isAtlantisEnabled) { newValue in
                self.demoAppConfig.isAtlantisEnabled = newValue
            }
        }
    }

    private func didSelectDemoAppOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [DemoAppConfigOption]
    ) {
        let option = options[indexPath.row]
        switch option {
        case .isHardDeleteEnabled:
            break
        case .isAtlantisEnabled:
            break
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
            cell.accessoryView = makeSwitchButton(chatClientConfig.isLocalStorageEnabled) { newValue in
                self.chatClientConfig.isLocalStorageEnabled = newValue
            }
        case .shouldShowShadowedMessages:
            cell.accessoryView = makeSwitchButton(chatClientConfig.shouldShowShadowedMessages) { newValue in
                self.chatClientConfig.shouldShowShadowedMessages = newValue
            }
        case .deletedMessagesVisibility:
            cell.detailTextLabel?.text = chatClientConfig.deletedMessagesVisibility.labelText
            cell.accessoryType = .disclosureIndicator
        }
    }

    private func didSelectChatClientOptionsCell(
        _ cell: UITableViewCell,
        at indexPath: IndexPath,
        options: [ChatClientConfigOption]
    ) {
        let option = options[indexPath.row]
        switch option {
        case .isLocalStorageEnabled:
            break
        case .shouldShowShadowedMessages:
            break
        case .deletedMessagesVisibility:
            makeDeletedMessagesVisibilitySelectorVC
        }
    }

    // MARK: View Factories

    private func makeSwitchButton(_ initialValue: Bool, _ didChangeValue: @escaping (Bool) -> Void) -> SwitchButton {
        let switchButton = SwitchButton()
        switchButton.isOn = initialValue
        switchButton.didChangeValue = didChangeValue
        return switchButton
    }

    private func makeDeletedMessagesVisibilitySelectorVC() {
        let selectorViewController = OptionsSelectorViewController(
            options: [.alwaysHidden, .alwaysVisible, .visibleForCurrentUser],
            initialSelectedOptions: [chatClientConfig.deletedMessagesVisibility],
            allowsMultipleSelection: false
        )
        selectorViewController.didChangeSelectedOptions = { options in
            guard let selectedOption = options.first else { return }
            self.chatClientConfig.deletedMessagesVisibility = selectedOption
        }

        navigationController?.pushViewController(selectorViewController, animated: true)
    }
}

extension ChatClientConfig.DeletedMessageVisibility: CustomStringConvertible {
    public var description: String {
        labelText
    }

    public var labelText: String {
        switch self {
        case .alwaysHidden:
            return "alwaysHidden"
        case .alwaysVisible:
            return "alwaysVisible"
        case .visibleForCurrentUser:
            return "visibleForCurrentUser"
        }
    }
}
