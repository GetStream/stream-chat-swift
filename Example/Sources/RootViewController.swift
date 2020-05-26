//
//  RootViewController.swift
//  ChatExample
//
//  Created by Alexey Bukhtin on 04/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import StreamChatClient
import StreamChatCore
import StreamChat

final class RootViewController: ViewController {
    
    @IBOutlet weak var splitViewButton: UIButton!
    @IBOutlet weak var totalUnreadCountLabel: UILabel!
    @IBOutlet weak var totalUnreadCountSwitch: UISwitch!
    @IBOutlet weak var unreadCountSwitch: UISwitch!
    @IBOutlet weak var unreadCountLabel: UILabel!
    @IBOutlet weak var onlinelabel: UILabel!
    @IBOutlet weak var onlineSwitch: UISwitch!
    @IBOutlet weak var notificationsSwitch: UISwitch!
    @IBOutlet weak var versionLabel: UILabel!
    
    let disposeBag = DisposeBag()
    var totalUnreadCountDisposeBag = DisposeBag()
    var unreadCountDisposeBag = DisposeBag()
    var watcherCountDisposeBag = DisposeBag()
    let subscriptionBag = SubscriptionBag()
    var channel = Client.shared.channel(type: .messaging, id: "general")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splitViewButton.isHidden = UIDevice.current.userInterfaceIdiom == .phone
        setupNotifications()
        navigationController?.navigationBar.prefersLargeTitles = true
        title = User.current.name
        
        if let avatarURL = User.current.avatarURL {
            DispatchQueue.global().async {
                guard let imageData = try? Data(contentsOf: avatarURL),
                    let avatar = UIImage(data: imageData)?.resized(targetSize: .init(width: 44, height: 44))?.original else {
                    return
                }
                
                DispatchQueue.main.async {
                    let barItem = UIBarButtonItem(image: avatar, style: .plain, target: nil, action: nil)
                    self.navigationItem.rightBarButtonItem = barItem
                }
            }
        }
        
        versionLabel.text = "Demo Project\nStream Swift SDK v.\(Environment.version)"
        
        totalUnreadCountSwitch.rx.isOn.changed
            .subscribe(onNext: { [weak self] isOn in
                if isOn {
                    self?.subscribeForTotalUnreadCount()
                } else {
                    self?.totalUnreadCountDisposeBag = DisposeBag()
                    self?.totalUnreadCountLabel.text = "Total Unread Count"
                }
            })
            .disposed(by: disposeBag)
        
        unreadCountSwitch.rx.isOn.changed
            .subscribe(onNext: { [weak self] isOn in
                if isOn {
                    self?.rxSubscribeForUnreadCount()
                } else {
                    self?.unreadCountDisposeBag = DisposeBag()
                    self?.unreadCountLabel.text = "Unread Count"
                }
            })
            .disposed(by: disposeBag)
        
        onlineSwitch.rx.isOn.changed
            .subscribe(onNext: { [weak self] isOn in
                if isOn {
                    self?.subscribeForWatcherCount()
                } else {
                    self?.watcherCountDisposeBag = DisposeBag()
                    self?.onlinelabel.text = "Watcher Count"
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "allChannels",
            let navigationController = segue.destination as? UINavigationController,
            let channelsViewController = navigationController.viewControllers.first as? ChannelsViewController {
            channelsViewController.presenter = ChannelsPresenter(filter: .currentUserInMembers)
        }
    }
    
    /// A classic way to subscribe for a channel unread count.
    @IBAction func subscribeForUnreadCount(_ sender: Any) {
        subscriptionBag.cancel()
        
        func unreadCountChanges(_ channel: Channel) -> Cancellable {
            channel.subscribeToUnreadCount { [weak self] result in
                DispatchQueue.main.async {
                    if let unreadCount = result.value {
                        self?.unreadCountLabel.text = "Unread Count: \(unreadCount.messages)"
                    } else if let error = result.error {
                        self?.show(error: error)
                        self?.unreadCountSwitch.isOn = false
                    }
                }
            }
        }
        
        if channel.isWatched {
            subscriptionBag.add(unreadCountChanges(channel))
            return
        }
        
        // Watch the channel.
        subscriptionBag.add(channel.watch({ [weak self] _ in
            guard let self = self else { return }
            
            // Request 100 messages to get the initial value of unread count.
            let subscription = self.channel.query(messagesPagination: [.limit(100)], options: [.watch, .state], { [weak self] in
                if let response = $0.value {
                    DispatchQueue.main.async {
                        self?.channel = response.channel
                        self?.subscriptionBag.add(unreadCountChanges(response.channel))
                    }
                }
            })
            
            self.subscriptionBag.add(subscription)
        }))
    }
    
    func rxSubscribeForUnreadCount() {
        let unreadCountChanges: (Channel) -> Observable<ChannelUnreadCount> = { [weak self] channel in
            channel.rx.unreadCount
                .observeOn(MainScheduler.instance)
                .do(onNext: { [weak self] unreadCount in self?.unreadCountLabel.text = "Unread Count: \(unreadCount.messages)" },
                    onError: { [weak self] in self?.show(error: $0); self?.unreadCountSwitch.isOn = false })
        }
        
        // Subscribe for the watched channel unread count changes.
        if channel.isWatched {
            unreadCountChanges(channel).subscribe().disposed(by: unreadCountDisposeBag)
            return
        }
        
        // Watch the channel and request 100 messages to get the initial value of unread count.
        channel.rx.watch()
            .flatMapLatest({ [weak self] _ in
                self?.channel.rx.query(messagesPagination: [.limit(100)], options: [.watch, .state]) ?? .empty()
            })
            .observeOn(MainScheduler.instance)
            .flatMapLatest({ [weak self] response -> Observable<ChannelUnreadCount> in
                self?.channel = response.channel
                return unreadCountChanges(response.channel)
            })
            .subscribe()
            .disposed(by: unreadCountDisposeBag)
    }
    
    func subscribeForWatcherCount() {
        let watcherCountChanges: (Channel) -> Observable<Int> = { [weak self] channel in
            channel.rx.watcherCount
                .observeOn(MainScheduler.instance)
                .do(onNext: { [weak self] in self?.onlinelabel.text = "Watcher Count: \($0)" },
                    onError: { [weak self] in self?.show(error: $0); self?.unreadCountSwitch.isOn = false })
        }
        
        // Subscribe for the watched channel watcher count changes.
        if channel.isWatched {
            watcherCountChanges(channel).subscribe().disposed(by: watcherCountDisposeBag)
            return
        }
        
        // Watch the channel and request 100 messages to get the initial value of unread count.
        channel.rx.query(messagesPagination: [.limit(1)], options: [.watch, .state])
            .observeOn(MainScheduler.instance)
            .flatMapLatest({ [weak self] response -> Observable<Int> in
                self?.channel = response.channel
                return watcherCountChanges(response.channel)
            })
            .subscribe()
            .disposed(by: watcherCountDisposeBag)
    }

    func subscribeForTotalUnreadCount() {
        Client.shared.rx.unreadCount
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] unreadCount in
                    self?.totalUnreadCountLabel.text = "Total unread channels \(unreadCount.channels), messages: \(unreadCount.messages)"
                    UIApplication.shared.applicationIconBadgeNumber = unreadCount.messages
                },
                onError: { [weak self] in
                    self?.show(error: $0)
                    self?.unreadCountSwitch.isOn = false
            })
            .disposed(by: totalUnreadCountDisposeBag)
    }
    
    func setupNotifications() {
        notificationsSwitch.rx.isOn.changed
            .flatMapLatest({ isOn -> Observable<Void> in
                if isOn {
                    Notifications.shared.askForPermissionsIfNeeded()
                    return .empty()
                }
                
                if let device = User.current.currentDevice {
                    return Client.shared.rx.removeDevice(deviceId: device.id).void()
                }
                
                return .empty()
            })
            .subscribe()
            .disposed(by: disposeBag)
    }
}

extension UIImage {
    fileprivate func resized(targetSize: CGSize) -> UIImage? {
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize: CGSize
        
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
