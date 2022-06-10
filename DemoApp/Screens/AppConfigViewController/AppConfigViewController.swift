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

    static var shared = AppConfig()

    private init() {
        // Default DemoAppConfig
        demoAppConfig = DemoAppConfig(
            isHardDeleteEnabled: false,
            isAtlantisEnabled: false
        )
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
        get { StreamChatWrapper.shared.config }
        set {
            StreamChatWrapper.shared.config = newValue
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
        case staysConnectedInBackground
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
            cell.accessoryView = makeSwitchButton(demoAppConfig.isHardDeleteEnabled) { [weak self] newValue in
                self?.demoAppConfig.isHardDeleteEnabled = newValue
            }
        case .isAtlantisEnabled:
            cell.accessoryView = makeSwitchButton(demoAppConfig.isAtlantisEnabled) { [weak self] newValue in
                self?.demoAppConfig.isAtlantisEnabled = newValue
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
        case .staysConnectedInBackground:
            break
        case .shouldShowShadowedMessages:
            break
        case .deletedMessagesVisibility:
            makeDeletedMessagesVisibilitySelectorVC()
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
        selectorViewController.didChangeSelectedOptions = { [weak self] options in
            guard let selectedOption = options.first else { return }
            self?.chatClientConfig.deletedMessagesVisibility = selectedOption
        }

        navigationController?.pushViewController(selectorViewController, animated: true)
    }
}
