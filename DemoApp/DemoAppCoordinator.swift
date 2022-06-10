//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class DemoAppCoordinator: NSObject {
    private let window: UIWindow
    private let chat: StreamChatWrapper
    private let pushNotifications: PushNotifications

    init(
        window: UIWindow,
        chat: StreamChatWrapper,
        pushNotifications: PushNotifications
    ) {
        self.window = window
        self.chat = chat
        self.pushNotifications = pushNotifications
        
        super.init()

        handlePushNotificationResponse()
    }
    
    func start(cid: ChannelId? = nil) {
        if let user = UserDefaults.shared.currentUser {
            showChat(for: .credentials(user), cid: cid, animated: false)
        } else {
            showLogin(animated: false)
        }
    }

    func handlePushNotificationResponse() {
        pushNotifications.onNotificationResponse = { [weak self] response in
            guard case UNNotificationDefaultActionIdentifier = response.actionIdentifier else {
                return
            }
            guard
                let chatNotificationInfo = self?.chat.notificationInfo(for: response),
                let cid = chatNotificationInfo.cid else {
                return
            }

            self?.start(cid: cid)
        }
    }
}

// MARK: - Navigation

private extension DemoAppCoordinator {
    func showChat(for user: DemoUserType, cid: ChannelId?, animated: Bool) {
        logIn(as: user)
        
        let chatVC = makeChatVC(for: user, startOn: cid) { [weak self] in
            guard let self = self else { return }
            
            self.logOut()
        }
        
        set(rootViewController: chatVC, animated: animated)
    }
    
    func showLogin(animated: Bool) {
        let loginVC = makeLoginVC { [weak self] user in
            self?.showChat(for: user, cid: nil, animated: true)
        }
        
        set(rootViewController: loginVC, animated: animated)
    }
    
    func set(rootViewController: UIViewController, animated: Bool) {
        if animated {
            UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft) {
                self.window.rootViewController = rootViewController
            }
        } else {
            window.rootViewController = rootViewController
        }
    }
}

// MARK: - Screens factory

private extension DemoAppCoordinator {
    func makeLoginVC(onUserSelection: @escaping (DemoUserType) -> Void) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginNVC = storyboard.instantiateInitialViewController() as! UINavigationController
        
        let loginVC = loginNVC.viewControllers.first as! LoginViewController
        loginVC.onUserSelection = onUserSelection
        
        return loginNVC
    }
    
    func makeChatVC(for user: DemoUserType, startOn cid: ChannelId?, onLogout: @escaping () -> Void) -> UIViewController {
        // Construct channel list query
        let channelListQuery: ChannelListQuery
        switch user {
        case let .credentials(userCredentials):
            channelListQuery = .init(filter: .containMembers(userIds: [userCredentials.id]))
        case .anonymous, .guest:
            channelListQuery = .init(filter: .equal(.type, to: .messaging))
        }

        let tuple = makeChannelVCs(for: cid)
        let selectedChannel = tuple.channelController?.channel
        let channelListController = chat.channelListController(query: channelListQuery)
        let channelListVC = makeChannelListVC(
            controller: channelListController,
            selectedChannel: selectedChannel,
            onLogout: onLogout
        )

        let channelListNVC = UINavigationController(rootViewController: channelListVC)
        let isIpad = UIDevice.current.userInterfaceIdiom == .pad
        if isIpad {
            let splitVC = UISplitViewController()
            splitVC.preferredDisplayMode = .oneBesideSecondary
            splitVC.viewControllers = [channelListNVC, tuple.channelNVC].compactMap { $0 }
            return splitVC
        } else {
            tuple.channelVC.map { channelListNVC.pushViewController($0, animated: false) }
            return channelListNVC
        }
    }
    
    func makeChannelListVC(
        controller: ChatChannelListController,
        selectedChannel: ChatChannel?,
        onLogout: @escaping () -> Void
    ) -> UIViewController {
        let channelListVC = DemoChatChannelListVC.make(with: controller)
        channelListVC.demoRouter.onLogout = onLogout
        channelListVC.selectedChannel = selectedChannel
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
    func logIn(as user: DemoUserType) {
        // Store current user id
        UserDefaults.shared.currentUserId = user.staticUserId

        // App configuration used by our dev team
        DemoAppConfiguration.setInternalConfiguration()

        chat.logIn(as: user)
    }
    
    func logOut() {
        // logout client
        chat.logOut()

        // clean user id
        UserDefaults.shared.currentUserId = nil

        // show login screen
        showLogin(animated: true)
    }
}

private extension DemoUserType {
    var staticUserId: UserId? {
        guard case let .credentials(user) = self else { return nil }
        
        return user.id
    }
}
