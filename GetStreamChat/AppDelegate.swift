//
//  AppDelegate.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 29/03/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import RxSwift
import RxCocoa

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Client.config = .init(apiKey: "qk4nn7rpcn75", logOptions: .all)
        
        Client.shared.set(user: User(id: "broken-waterfall-5",
                                     name: "Jon Snow",
                                     avatarURL: URL(string: "https://bit.ly/2u9Vc0r")),
                          token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg")
        
        Fabric.with([Crashlytics.self])
        setupNotifications()
        
        // Dark style for the second tab bar item.
        if let tabBarController = window?.rootViewController as? UITabBarController,
            let navigationController = tabBarController.viewControllers?[1] as? UINavigationController,
            let darkChannelsViewController = navigationController.viewControllers.first as? ChannelsViewController {
            setupChatWithDarkStyle(darkChannelsViewController)
        }
        
        return true
    }
    
    private func setupChatWithDarkStyle(_ channelsViewController: ChannelsViewController) {
        channelsViewController.style = .dark
        
        let addChannelButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        channelsViewController.navigationItem.rightBarButtonItem = addChannelButton
        
        addChannelButton.rx.tap
            .subscribe(onNext: { [weak self, weak channelsViewController] _ in self?.promptChannelName(channelsViewController) })
            .disposed(by: channelsViewController.disposeBag)
    }
    
    private func promptChannelName(_ viewController: ChannelsViewController?) {
        let alert = UIAlertController(title: "Create a Channel", message: "Type a channel name", preferredStyle: .alert)
        alert.addTextField()

        alert.addAction(.init(title: "Create", style: .default, handler: { [weak alert, weak self] _ in
            if let textFields = alert?.textFields?.first, let name = textFields.text {
                self?.createChannel(name: name, for: viewController)
            }
        }))
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in }))
        
        window?.rootViewController?.present(alert, animated: true)
    }
    
    private func createChannel(name: String, for viewController: ChannelsViewController?) {
        guard let viewController = viewController else {
            return
        }
        
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = name.lowercased().replacingOccurrences(of: " ", with: "_")
        
        Channel.create(id: id, name: name)
            .subscribe(onError: { print("Create a channel error:", $0) })
            .disposed(by: viewController.disposeBag)
    }
    
    private func setupNotifications() {
        Notifications.shared.askForPermissionsIfNeeded()
        
        Notifications.shared.openNewMessage = { [weak self] messageId, channelId in
            if let tabBarController = self?.window?.rootViewController as? UITabBarController,
                let navigationViewController = tabBarController.viewControllers?.first as? UINavigationController,
                let channelsViewController = navigationViewController.viewControllers.first as? ChannelsViewController,
                let channelIndex = channelsViewController.channelsPresenter.items.firstIndex(where: { chatItem -> Bool in
                    if case .channel(let channelPresenter) = chatItem, channelPresenter.channel.id == channelId {
                        return true
                    }
                    
                    return false
                }) {
                channelsViewController.navigationController?.viewControllers = [channelsViewController]
                channelsViewController.showChatViewController(at: channelIndex)
            }
        }
    }
}
