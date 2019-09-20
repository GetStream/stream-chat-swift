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
import StreamChatCore

final class RootViewController: UIViewController {
    
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var badgeSwitch: UISwitch!
    @IBOutlet weak var onlinelabel: UILabel!
    @IBOutlet weak var onlineSwitch: UISwitch!
    @IBOutlet weak var notificationsSwitch: UISwitch!
    
    let disposeBag = DisposeBag()
    var badgeDisposeBag = DisposeBag()
    var onlineDisposeBag = DisposeBag()
    let channel = Channel(type: .messaging, id: "general")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNotifications()
        
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
                    self?.onlinelabel.text = "Online users: <Disabled>"
                }
            })
            .disposed(by: disposeBag)
    }
    
    func subscribeForUnreadCount() {
        channel.unreadCount
            .drive(onNext: { [weak self] count in
                self?.badgeLabel.text = "\(count == 100 ? "99+" : String(count))  "
                UIApplication.shared.applicationIconBadgeNumber = count
            })
            .disposed(by: badgeDisposeBag)
    }
    
    func subscribeForOnlineUsers() {
        channel.onlineUsers
            .startWith([User(id: "", name: "")])
            .drive(onNext: { [weak self] users in
                if users.count == 1, users[0].id.isEmpty {
                    self?.onlinelabel.text = "Online users: <Loading...>"
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
                
                self?.onlinelabel.text = "Online users: \(userNames)"
            })
            .disposed(by: onlineDisposeBag)
    }
    
    func setupNotifications() {
        notificationsSwitch.rx.isOn.changed
            .flatMapLatest { isOn -> Observable<Void> in
                if isOn {
                    Notifications.shared.askForPermissionsIfNeeded()
                    return .empty()
                }
                
                if let device = User.current?.currentDevice {
                    return Client.shared.removeDevice(deviceId: device.id)
                }
                
                return .empty()
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
}
