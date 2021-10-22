//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoChatChannelListRouter: ChatChannelListRouter {
    enum ChannelPresentingStyle {
        case push
        case modally
        case embeddedInTabBar
    }

    var channelPresentingStyle: ChannelPresentingStyle = .push

    func showCreateNewChannelFlow() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        let chatViewController = storyboard.instantiateViewController(withIdentifier: "CreateChatViewController")
            as! CreateChatViewController
        chatViewController.searchController = rootViewController.controller.client.userSearchController()
        
        rootNavigationController?.pushViewController(chatViewController, animated: true)
    }
    
    override func showCurrentUserProfile() {
        rootViewController.presentAlert(title: nil, actions: [
            .init(title: "Logout", style: .destructive, handler: { _ in
                let window = self.rootViewController.view.window!
                guard let navigationController = UIStoryboard(name: "Main", bundle: Bundle.main)
                    .instantiateInitialViewController() as? UINavigationController else {
                    return
                }
                guard let sceneDelegate = window.windowScene?.delegate as? SceneDelegate else {
                    return
                }
                sceneDelegate.coordinator = DemoAppCoordinator(navigationController: navigationController)
                UIView.transition(with: window, duration: 0.3, options: .transitionFlipFromLeft, animations: {
                    window.rootViewController = navigationController
                })
            })
        ])
    }

    override func showChannel(for cid: ChannelId) {
        switch channelPresentingStyle {
        case .push:
            super.showChannel(for: cid)

        case .modally:
            let vc = components.channelVC.init()
            vc.channelController = rootViewController.controller.client.channelController(for: cid)
            rootNavigationController?.present(vc, animated: true, completion: nil)

        case .embeddedInTabBar:
            let vc = components.channelVC.init()
            vc.channelController = rootViewController.controller.client.channelController(for: cid)
            vc.tabBarItem = .init(title: "Chat", image: nil, tag: 0)

            let tabBarController = UITabBarController()
            tabBarController.viewControllers = [vc]
            // Make the tab bar not translucent to make sure the
            // keyboard handling works in all conditions.
            tabBarController.tabBar.isTranslucent = false

            rootNavigationController?.show(tabBarController, sender: self)
        }
    }
    
    override func didTapMoreButton(for cid: ChannelId) {
        let channelController = rootViewController.controller.client.channelController(for: cid)
        rootViewController.presentAlert(title: "Select an action", actions: [
            .init(title: "Change nav bar translucency", style: .default, handler: { _ in
                self.rootViewController.presentAlert(
                    title: "Change nav bar translucency",
                    message: "Change the nav bar translucency to verify that the keyboard handling is working in different app setups.",
                    actions: [
                        .init(title: "Is Translucent", style: .default, handler: { _ in
                            self.rootViewController.navigationController?.navigationBar.isTranslucent = true
                        }),
                        .init(title: "Not Translucent", style: .default, handler: { _ in
                            self.rootViewController.navigationController?.navigationBar.isTranslucent = false
                        })
                    ],
                    cancelHandler: nil
                )
            }),
            .init(title: "Change channel presentation style", style: .default, handler: { _ in
                self.rootViewController.presentAlert(
                    title: "Change channel presentation style",
                    message: "Change how the channel navigation is presented.",
                    actions: [
                        .init(title: "Push (Default)", style: .default, handler: { _ in
                            self.channelPresentingStyle = .push
                        }),
                        .init(title: "Modally", style: .default, handler: { _ in
                            self.channelPresentingStyle = .modally
                        }),
                        .init(title: "Embedded in Tab Bar", style: .default, handler: { _ in
                            self.channelPresentingStyle = .embeddedInTabBar
                        })
                    ],
                    cancelHandler: nil
                )
                self.channelPresentingStyle = .embeddedInTabBar
            }),
            .init(title: "Update channel name", style: .default, handler: { _ in
                self.rootViewController.presentAlert(title: "Enter channel name", textFieldPlaceholder: "Channel name") { name in
                    guard let name = name, !name.isEmpty else {
                        self.rootViewController.presentAlert(title: "Name is not valid")
                        return
                    }
                    channelController.updateChannel(
                        name: name,
                        imageURL: channelController.channel?.imageURL,
                        team: channelController.channel?.team
                    ) { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't update name of channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Update channel image", style: .default, handler: { _ in
                self.rootViewController.presentAlert(
                    title: "Enter channel image url",
                    textFieldPlaceholder: "Channel image url, must be valid"
                ) { imageURL in
                    guard let imageURL = imageURL, !imageURL.isEmpty, let url = URL(string: imageURL) else {
                        self.rootViewController.presentAlert(title: "URL is not valid")
                        return
                    }
                    channelController.updateChannel(
                        name: channelController.channel?.name,
                        imageURL: url,
                        team: channelController.channel?.team,
                        extraData: channelController.channel?.extraData ?? [:]
                    ) { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't update image url of channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Add member", style: .default, handler: { _ in
                self.rootViewController.presentAlert(title: "Enter user id", textFieldPlaceholder: "User ID") { id in
                    guard let id = id, !id.isEmpty else {
                        self.rootViewController.presentAlert(title: "User ID is not valid")
                        return
                    }
                    channelController.addMembers(userIds: [id]) { error in
                        if let error = error {
                            self.rootViewController.presentAlert(
                                title: "Couldn't add user \(id) to channel \(cid)",
                                message: "\(error)"
                            )
                        }
                    }
                }
            }),
            .init(title: "Remove a member", style: .default, handler: { _ in
                let actions = channelController.channel?.lastActiveMembers.map { member in
                    UIAlertAction(title: member.id, style: .default) { _ in
                        channelController.removeMembers(userIds: [member.id]) { error in
                            if let error = error {
                                self.rootViewController.presentAlert(
                                    title: "Couldn't remove user \(member.id) from channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
                } ?? []
                self.rootViewController.presentAlert(title: "Select a member", actions: actions)
            }),
            .init(title: "Freeze channel", style: .default, handler: { _ in
                channelController.freezeChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't freeze channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Unfreeze channel", style: .default, handler: { _ in
                channelController.unfreezeChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't unfreeze channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Mute channel", style: .default, handler: { _ in
                channelController.muteChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't mute channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Unmute channel", style: .default, handler: { _ in
                channelController.unmuteChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't unmute channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Freeze channel", style: .default, handler: { _ in
                channelController.freezeChannel { error in
                    if let error = error {
                        self.rootViewController.presentAlert(title: "Couldn't freeze channel \(cid)", message: "\(error)")
                    }
                }
            }),
            .init(title: "Enable slow mode", style: .default, handler: { _ in
                self.rootViewController
                    .presentAlert(title: "Enter cooldown", textFieldPlaceholder: "Cooldown duration, 0-120") { cooldown in
                        guard let cooldown = cooldown, !cooldown.isEmpty, let duration = Int(cooldown) else {
                            self.rootViewController.presentAlert(title: "Cooldown duration is not valid")
                            return
                        }
                        channelController.enableSlowMode(cooldownDuration: duration) { error in
                            if let error = error {
                                self.rootViewController.presentAlert(
                                    title: "Couldn't enable slow mode on channel \(cid)",
                                    message: "\(error)"
                                )
                            }
                        }
                    }
            }),
            .init(title: "Disable slow mode", style: .default, handler: { _ in
                channelController.disableSlowMode { error in
                    if let error = error {
                        self.rootViewController.presentAlert(
                            title: "Couldn't disable slow mode on channel \(cid)",
                            message: "\(error)"
                        )
                    }
                }
            }),
            (
                channelController.channel?.isHidden == false ?
                    .init(title: "Hide channel", style: .default, handler: { _ in
                        channelController.hideChannel { error in
                            if let error = error {
                                self.rootViewController.presentAlert(title: "Couldn't hide channel \(cid)", message: "\(error)")
                            }
                        }
                    }) :
                    .init(title: "Show channel", style: .default, handler: { _ in
                        channelController.showChannel() { error in
                            if let error = error {
                                self.rootViewController.presentAlert(title: "Couldn't unhide channel \(cid)", message: "\(error)")
                            }
                        }
                    })
            ),
            .init(title: "Show Channel Info", style: .default, handler: { _ in
                self.rootViewController.presentAlert(
                    title: "Channel Info",
                    message: channelController.channel.debugDescription
                )
            })
        ])
    }
    
    override func didTapDeleteButton(for cid: ChannelId) {
        rootViewController.controller.client.channelController(for: cid).deleteChannel { error in
            if let error = error {
                self.rootViewController.presentAlert(title: "Channel \(cid) couldn't be deleted", message: "\(error)")
            }
        }
    }
}

class DemoChannelListVC: ChatChannelListVC {
    /// The `UIButton` instance used for navigating to new channel screen creation,
    lazy var createChannelButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "plus.message")!, for: .normal)
        return button
    }()
    
    lazy var hiddenChannelsButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "archivebox")!, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: hiddenChannelsButton),
            UIBarButtonItem(customView: createChannelButton)
        ]
        createChannelButton.addTarget(self, action: #selector(didTapCreateNewChannel), for: .touchUpInside)
        hiddenChannelsButton.addTarget(self, action: #selector(didTapHiddenChannelsButton), for: .touchUpInside)
    }

    @objc private func didTapCreateNewChannel(_ sender: Any) {
        (router as! DemoChatChannelListRouter).showCreateNewChannelFlow()
    }
    
    @objc private func didTapHiddenChannelsButton(_ sender: Any) {
        let channelListVC = HiddenChannelListVC()
        channelListVC.controller = controller
            .client
            .channelListController(
                query: .init(
                    filter: .and(
                        [
                            .containMembers(userIds: [controller.client.currentUserId!]),
                            .equal(.hidden, to: true)
                        ]
                    )
                )
            )
        navigationController?.pushViewController(channelListVC, animated: true)
    }
    
    override func controller(_ controller: ChatChannelListController, shouldListUpdatedChannel channel: ChatChannel) -> Bool {
        channel.lastActiveMembers.contains(where: { $0.id == controller.client.currentUserId })
    }
    
    override func controller(_ controller: ChatChannelListController, shouldAddNewChannelToList channel: ChatChannel) -> Bool {
        channel.lastActiveMembers.contains(where: { $0.id == controller.client.currentUserId })
    }
}

class HiddenChannelListVC: ChatChannelListVC {
    override func setUpAppearance() {
        super.setUpAppearance()
        
        title = "Hidden Channels"
        navigationItem.leftBarButtonItem = nil
    }
}
