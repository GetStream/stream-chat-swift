//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

// MARK: - Navigation

extension DemoAppCoordinator {
    var chat: StreamChatWrapper {
        StreamChatWrapper.shared
    }

    func start(cid: ChannelId? = nil, completion: @escaping (Error?) -> Void) {
        if let user = UserDefaults.shared.currentUser {
            showChat(for: .credentials(user), cid: cid, animated: false, completion: completion)
        } else {
            showLogin(animated: false)
        }
    }

    func showChat(for user: DemoUserType, cid: ChannelId?, animated: Bool, completion: @escaping (Error?) -> Void) {
        logIn(as: user, completion: completion)

        let chatVC = makeChatVC(
            for: user,
            startOn: cid,
            onLogout: { [weak self] in
                self?.logOut()
            },
            onDisconnect: { [weak self] in
                self?.disconnect()
            }
        )

        let client = StreamChatWrapper.shared.client!
        let threadListQuery = ThreadListQuery(watch: true)
        let threadListVC = DemoChatThreadListVC(
            threadListController: client.threadListController(query: threadListQuery),
            eventsController: client.eventsController()
        )
        threadListVC.onLogout = { [weak self] in
            self?.logOut()
        }
        threadListVC.onDisconnect = { [weak self] in
            self?.disconnect()
        }
        
        let draftsVC = DemoDraftMessageListVC(
            currentUserController: client.currentUserController()
        )
        draftsVC.onLogout = { [weak self] in
            self?.logOut()
        }
        draftsVC.onDisconnect = { [weak self] in
            self?.disconnect()
        }
        
        let reminderListVC = DemoReminderListVC(
            currentUserController: client.currentUserController()
        )
        reminderListVC.onLogout = { [weak self] in
            self?.logOut()
        }
        reminderListVC.onDisconnect = { [weak self] in
            self?.disconnect()
        }

        let tabBarViewController = DemoAppTabBarController(
            channelListVC: chatVC,
            threadListVC: UINavigationController(rootViewController: threadListVC),
            draftListVC: UINavigationController(rootViewController: draftsVC),
            reminderListVC: UINavigationController(rootViewController: reminderListVC),
            currentUserController: client.currentUserController(),
            allRemindersListController: client.messageReminderListController()
        )
        set(rootViewController: tabBarViewController, animated: animated)
        DemoAppConfiguration.showPerformanceTracker()
    }

    func showLogin(animated: Bool) {
        let loginVC = makeLoginVC { [weak self] user in
            self?.showChat(for: user, cid: nil, animated: true) { error in
                if let error = error {
                    log.error("Something went wrong logging in: \(error)")
                }
            }
        }

        if let loginVC = loginVC {
            set(rootViewController: loginVC, animated: animated)
        }
    }
}

// MARK: - Screens factory

extension DemoAppCoordinator {
    func makeLoginVC(onUserSelection: @escaping (DemoUserType) -> Void) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginNVC = storyboard.instantiateInitialViewController() as? UINavigationController,
           let loginVC = loginNVC.viewControllers.first as? LoginViewController {
            loginVC.onUserSelection = onUserSelection
            return loginNVC
        }

        return nil
    }

    func makeChatVC(
        for user: DemoUserType,
        startOn cid: ChannelId?,
        onLogout: @escaping () -> Void,
        onDisconnect: @escaping () -> Void
    ) -> UIViewController {
        // Construct channel list query
        let sorting: [Sorting<ChannelListSortingKey>] = [
            Sorting(key: .pinnedAt),
            Sorting(key: .default)
        ]
        let channelListQuery: ChannelListQuery
        switch user {
        case let .credentials(userCredentials):
            channelListQuery = .init(
                filter: .containMembers(userIds: [userCredentials.id]),
                sort: sorting
            )
        case let .custom(userCredentials):
            guard let userId = userCredentials?.id else {
                fallthrough
            }
            channelListQuery = .init(
                filter: .containMembers(userIds: [userId]),
                sort: sorting
            )
        case .anonymous, .guest:
            channelListQuery = .init(
                filter: .equal(.type, to: .messaging),
                sort: sorting
            )
        }

        let tuple = makeChannelVCs(for: cid)
        let selectedChannel = tuple.channelController?.channel
        guard let channelListController = chat.channelListController(query: channelListQuery) else {
            return UIViewController()
        }
        let channelListVC = makeChannelListVC(
            controller: channelListController,
            selectedChannel: selectedChannel,
            onLogout: onLogout,
            onDisconnect: onDisconnect
        )

        let channelListNVC = UINavigationController(rootViewController: channelListVC)
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        if isIpad {
            let splitVC = UISplitViewController()
            splitVC.preferredDisplayMode = .oneBesideSecondary
            splitVC.viewControllers = [channelListNVC, tuple.channelNVC].compactMap { $0 }
            return splitVC
        } else if let channelVC = tuple.channelVC {
            channelListNVC.pushViewController(channelVC, animated: false)
        }
        return channelListNVC
    }

    func makeChannelListVC(
        controller: ChatChannelListController,
        selectedChannel: ChatChannel?,
        onLogout: @escaping () -> Void,
        onDisconnect: @escaping () -> Void
    ) -> UIViewController {
        let channelListVC = DemoChatChannelListVC.make(with: controller)
        channelListVC.demoRouter?.onLogout = onLogout
        channelListVC.demoRouter?.onDisconnect = onDisconnect
        channelListVC.selectedChannel = selectedChannel
        channelListVC.components.isChatChannelListStatesEnabled = true
        return channelListVC
    }

    func makeChannelVC(controller: ChatChannelController) -> UIViewController {
        let channelVC = DemoChatChannelVC()
        channelVC.channelController = controller
        return channelVC
    }

    // Creates channel controller, channel VC and navigation controller for given channel id
    private func makeChannelVCs(for cid: ChannelId?)
        -> (channelController: ChatChannelController?, channelVC: UIViewController?, channelNVC: UINavigationController?) {
        guard let cid = cid else {
            return (nil, nil, nil)
        }
        // Get channel controller (model)
        let controller = chat.channelController(for: cid)

        // Create channel VC with given controller
        let channelVC = controller.map { makeChannelVC(controller: $0) }
        let channelNVC = channelVC.map { UINavigationController(rootViewController: $0) }

        return (controller, channelVC, channelNVC)
    }
}

// MARK: - User Auth

private extension DemoAppCoordinator {
    func logIn(as user: DemoUserType, completion: @escaping (Error?) -> Void) {
        // Store current user id
        UserDefaults.shared.currentUserId = user.staticUserId

        // App configuration used by our dev team
        DemoAppConfiguration.setInternalConfiguration()

        if let userCredentials = user.userCredentials, let customApiKey = userCredentials.customApiKey {
            StreamChatWrapper.replaceSharedInstance(apiKeyString: customApiKey)
        }

        chat.logIn(as: user, completion: completion)
    }

    func logOut() {
        chat.logOut { [weak self] in
            UserDefaults.shared.currentUserId = nil
            self?.showLogin(animated: true)
        }
    }

    func disconnect() {
        chat.client?.disconnect { [weak self] in
            DispatchQueue.main.async {
                self?.showLogin(animated: true)
            }
        }
    }
}

private extension DemoUserType {
    var staticUserId: UserId? {
        guard case let .credentials(user) = self else { return nil }

        return user.id
    }
}
