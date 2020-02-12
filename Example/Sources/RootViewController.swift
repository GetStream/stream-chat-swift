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

final class RootViewController: UIViewController {
    
    @IBOutlet weak var splitViewButton: UIButton!
    @IBOutlet weak var splitViewSeparator: UIView!
    @IBOutlet weak var totalUnreadCountLabel: UILabel!
    @IBOutlet weak var totalUnreadCountSwitch: UISwitch!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var badgeSwitch: UISwitch!
    @IBOutlet weak var onlinelabel: UILabel!
    @IBOutlet weak var onlineSwitch: UISwitch!
    @IBOutlet weak var notificationsSwitch: UISwitch!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var offlineMode: UISwitch!
    
    let disposeBag = DisposeBag()
    var totalUnreadCountDisposeBag = DisposeBag()
    var badgeDisposeBag = DisposeBag()
    var onlineDisposeBag = DisposeBag()
    let channel = Channel(type: .messaging, id: "general")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splitViewButton.isHidden = UIDevice.current.userInterfaceIdiom == .phone
        splitViewSeparator.isHidden = UIDevice.current.userInterfaceIdiom == .phone
        setupNotifications()
        navigationController?.navigationBar.prefersLargeTitles = true
        
        if User.current.isUnknown {
            navigationController?.popViewController(animated: true)
            return
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: User.current.name.capitalized,
                                                            style: .plain,
                                                            target: nil,
                                                            action: nil)

        versionLabel.text = "Demo Project\nStream Swift SDK v.\(Client.version)"
        
        totalUnreadCountSwitch.rx.isOn.changed
            .subscribe(onNext: { [weak self] isOn in
                if isOn {
                    self?.subscribeForTotalUnreadCount()
                } else {
                    self?.totalUnreadCountDisposeBag = DisposeBag()
                    self?.totalUnreadCountLabel.text = "Total unread count: <Disabled>"
                }
            })
            .disposed(by: disposeBag)
        
        badgeSwitch.rx.isOn.changed
            .subscribe(onNext: { [weak self] isOn in
                if isOn {
                    self?.subscribeForUnreadCount()
                } else {
                    self?.badgeDisposeBag = DisposeBag()
                    self?.badgeLabel.text = "–"
                }
            })
            .disposed(by: disposeBag)
        
        onlineSwitch.rx.isOn.changed
            .subscribe(onNext: { [weak self] isOn in
                if isOn {
                    self?.subscribeForOnlineUsers()
                } else {
                    self?.onlineDisposeBag = DisposeBag()
                    self?.onlinelabel.text = "Online members: <Disabled>"
                }
            })
            .disposed(by: disposeBag)
        
        offlineMode.rx.isOn.changed
            .subscribe(onNext: { InternetConnection.shared.offlineMode = $0 })
            .disposed(by: disposeBag)
    }
    
    @IBAction func checkForBan(_ sender: Any) {
        Client.shared.rx.connection
            .filter({ $0.isConnected })
            .take(1)
            .subscribe(onNext: { _ in
                if User.current.isBanned {
                    Banners.shared.show("🙅‍♂️ You are banned")
                } else {
                    Banners.shared.show("👍 You are not banned")
                }
            })
            .disposed(by: disposeBag)
    }
    
    func subscribeForTotalUnreadCount() {
        Client.shared.rx.unreadCount
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] unreadCount in
                self?.totalUnreadCountLabel.text = "Unread channels \(unreadCount.channels), messages: \(unreadCount.messages)"
                UIApplication.shared.applicationIconBadgeNumber = unreadCount.messages
            })
            .disposed(by: totalUnreadCountDisposeBag)
    }
    
    func subscribeForUnreadCount() {
        channel.rx.unreadCount
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] unreadCount in
                self?.badgeLabel.text = "\(unreadCount.messages >= 100 ? "99+" : String(unreadCount.messages))  "
            })
            .disposed(by: badgeDisposeBag)
    }
    
    func subscribeForOnlineUsers() {
        channel.rx.onlineUsers
            .observeOn(MainScheduler.instance)
            .startWith([User(id: "", name: "")])
            .subscribe(onNext: { [weak self] users in
                let users = Array(users)
                if users.count == 1, users[0].id.isEmpty {
                    self?.onlinelabel.text = "Online members: <Loading...>"
                    return
                }
                
                var userNames = "<Nobody>"
                
                if users.count == 1 {
                    userNames = users[0].name
                } else if users.count == 2 {
                    userNames = "\(users[0].name) and \(users[1].name)"
                } else if users.count == 3 {
                    userNames = "\(users[0].name), \(users[1].name) and \(users[2].name)"
                } else if users.count > 3 {
                    userNames = "\(users[0].name), \(users[1].name), \(users[2].name) and \(users.count - 3) others"
                }
                
                self?.onlinelabel.text = "Online: \(userNames)"
            })
            .disposed(by: onlineDisposeBag)
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
