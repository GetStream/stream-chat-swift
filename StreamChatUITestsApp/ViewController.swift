//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

final class ViewController: UIViewController {

    var streamChat = StreamChatWrapper()
    var settings = Settings()

    var channelController: ChatChannelController?
    var router: CustomChannelListRouter?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        let stackView = UIStackView(arrangedSubviews: createSettingsViews())
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(createStartButton())
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc func didTap() {
        // Setup chat client
        streamChat.setupChatClient(with: .default)

        // create UI
        let channelList = streamChat.makeChannelListViewController()
        router = channelList.router as? CustomChannelListRouter

        router?.onChannelListViewWillAppear = { [weak self] channelListVC in
            channelListVC.navigationItem.titleView = self?.createIsConnectedSwitchIfNeeded()
        }
        router?.onChannelViewWillAppear = { [weak self] channelVC in
            guard let self = self else { return }
            self.channelController = channelVC.channelController
            let switchControl = self.createIsConnectedSwitchIfNeeded()
            if let switchControl = switchControl {
                channelVC.navigationItem.titleView = switchControl
            }

            // Show debug button on the right side
            channelVC.navigationItem.rightBarButtonItems?.append(self.createDebugButton())
        }

        // Settings
        handleSettings(for: channelList)

        // push to detail presentation
        navigationController?.pushViewController(channelList, animated: false)

        // pops when tapped on user icon
        router?.onLeave = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    func handleSettings(for channelListVC: UIViewController) {
        if settings.setConnectivity.isOn {
            streamChat.mockConnection(isConnected: settings.isConnected.isOn)
        }
    }

    @objc func didChangeSetting(_ sw: UISwitch) {
        settings.updateSetting(with: sw.accessibilityIdentifier, isOn: sw.isOn)
    }

    @objc func valueChanged(_ sw: UISwitch) {
        settings.isConnected.isOn = sw.isOn
        streamChat.mockConnection(isConnected: settings.isConnected.isOn)
    }

    @objc func showDebugMenu() {
        if let controller = channelController {
            DebugMenu.shared.showMenu(in: self, channelController: controller)
        }
    }

}

// MARK: UI Components

extension ViewController {

    func createIsConnectedSwitchIfNeeded() -> UISwitch? {
        guard self.settings.showsConnectivity.isOn else { return nil }
        let sw = UISwitch()
        sw.isOn = self.settings.isConnected.isOn
        sw.accessibilityIdentifier = self.settings.isConnected.setting.rawValue
        sw.addTarget(self, action: #selector(self.valueChanged(_:)), for: .valueChanged)

        return sw
    }

    func createSettingsViews() -> [UIView] {
        settings.all.map { setting in
            let label = UILabel()
            label.text = setting.setting.rawValue
            label.textColor = .yellow
            label.translatesAutoresizingMaskIntoConstraints = false

            let sw = UISwitch()
            sw.isOn = setting.isOn
            sw.translatesAutoresizingMaskIntoConstraints = false
            sw.accessibilityIdentifier = label.text
            sw.addTarget(self, action: #selector(didChangeSetting(_:)), for: .valueChanged)

            let stackView = UIStackView(arrangedSubviews: [label, sw])
            stackView.axis = .horizontal
            stackView.alignment = .leading
            stackView.distribution = .fillProportionally
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }
    }

    func createStartButton() -> UIButton {
        let startButton = UIButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Start Chat", for: .normal)
        startButton.accessibilityIdentifier = "TestApp.Start"
        startButton.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        return startButton
    }

    func createDebugButton() -> UIBarButtonItem {
        let item = UIBarButtonItem(
            image: UIImage(named: "pencil")!,
            style: .plain,
            target: self,
            action: #selector(self.showDebugMenu)
        )
        item.accessibilityIdentifier = "debug"
        return item
    }

}
