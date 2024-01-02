//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

var settings = Settings()

final class ViewController: UIViewController {

    var streamChat = StreamChatWrapper.shared

    var channelController: ChatChannelController?
    var router: CustomChannelListRouter?
    var messageListRouter: CustomMessageListRouter?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        let stackView = UIStackView(arrangedSubviews: createSettingsViews())
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(createStartButton())
        stackView.addArrangedSubview(createConnectGuestButton())
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc func didTap() {
        // Setup chat client
        streamChat.setUpChat()
        streamChat.connectUser(completion: { _ in })
        showChannelList()
    }

    @objc func didTapConnectGuest() {
        // Setup chat client
        streamChat.setUpChat()
        streamChat.connectGuestUser(completion: { _ in })
        showChannelList()
    }

    private func showChannelList() {
        // create UI
        let channelList = streamChat.makeChannelListViewController()
        router = channelList.router as? CustomChannelListRouter

        // create connection switch if needed
        let switchControl = self.createIsConnectedSwitchIfNeeded()

        router?.onChannelListViewWillAppear = { channelListVC in
            // show connection switch if needed
            if let sw = switchControl {
                channelListVC.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sw)
            }
        }
        router?.onChannelViewWillAppear = { [weak self] channelVC in
            guard let self = self else { return }
            self.channelController = channelVC.channelController

            // show connection switch if needed
            if let sw = switchControl {
                channelVC.navigationItem.rightBarButtonItems?.append(UIBarButtonItem(customView: sw))
            }

            // Show debug button on the right side
            channelVC.navigationItem.rightBarButtonItems?.append(self.createDebugButton())

            // Hook on mesage list router
            self.configureMessageListRouter(router: channelVC.messageListVC.router)
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

    private func configureMessageListRouter(router: ChatMessageListRouter) {
        guard let router = router as? CustomMessageListRouter else {
            return
        }

        self.messageListRouter = router
        messageListRouter?.onThreadViewWillAppear = { [weak self] threadVC in
            guard let self = self else { return }
            threadVC.navigationItem.rightBarButtonItem = self.createDebugButton()
            threadVC.navigationItem.titleView = self.createIsConnectedSwitchIfNeeded()
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
        guard settings.showsConnectivity.isOn else { return nil }
        let sw = UISwitch()
        sw.isOn = settings.isConnected.isOn
        sw.accessibilityIdentifier = settings.isConnected.setting.rawValue
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

    func createConnectGuestButton() -> UIButton {
        let startButton = UIButton(type: .system)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Connect Guest", for: .normal)
        startButton.accessibilityIdentifier = "TestApp.ConnectGuest"
        startButton.addTarget(self, action: #selector(didTapConnectGuest), for: .touchUpInside)
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

extension StreamChatWrapper {
    func connectUser(completion: @escaping (Error?) -> Void) {
        let userCredentials = UserCredentials.default
        let tokenProvider = mockTokenProvider(for: userCredentials)
        client?.connectUser(
            userInfo: userCredentials.userInfo,
            tokenProvider: tokenProvider,
            completion: completion
        )
    }

    func connectGuestUser(completion: @escaping (Error?) -> Void) {
        client?.connectGuestUser(
            userInfo: .init(id: "123"),
            completion: completion
        )
    }

    func mockTokenProvider(for userCredentials: UserCredentials) -> TokenProvider {
        return { completion in
            if ProcessInfo.processInfo.arguments.contains("MOCK_JWT") {
                let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? ""
                let urlString = "http://localhost:4567/jwt/\(udid)?api_key=\(apiKeyString)&user_name=\(userCredentials.id)"
                guard let url = URL(string: urlString) else { return }

                var request = URLRequest(url: url)
                request.httpMethod = "GET"

                URLSession.shared.dataTask(with: request) { result in
                    switch result {
                    case .success((_, let data)):
                        guard let body = String(data: data, encoding: .utf8) else { return }
                        let generatedToken = Token(stringLiteral: body)
                        completion(.success(generatedToken))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                .resume()
            } else {
                completion(.success(userCredentials.token))
            }
        }
    }
}

extension URLSession {

    enum HTTPError: Error {
        case transportError(Error)
        case serverSideError(Int)
    }

    typealias DataTaskResult = Result<(HTTPURLResponse, Data), Error>

    func dataTask(with request: URLRequest, completionHandler: @escaping (DataTaskResult) -> Void) -> URLSessionDataTask {
        return self.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(Result.failure(HTTPError.transportError(error)))
                return
            }

            guard let response = response as? HTTPURLResponse else { return }

            guard (200...299).contains(response.statusCode) else {
                completionHandler(Result.failure(HTTPError.serverSideError(response.statusCode)))
                return
            }

            guard let data = data else { return }

            completionHandler(Result.success((response, data)))
        }
    }
}
