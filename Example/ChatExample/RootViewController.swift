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
    @IBOutlet weak var onlinelabel: UILabel!
    
    let disposeBag = DisposeBag()
    let channel = Channel(type: .messaging, id: "general")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        channel.unreadCount
            .drive(onNext: { [weak self] count in
                self?.badgeLabel.text = "\(count == 100 ? "99+" : String(count))  "
                UIApplication.shared.applicationIconBadgeNumber = count
            })
            .disposed(by: disposeBag)
        
        channel.onlineUsers
            .drive(onNext: { [weak self] users in
                var userNames = "0"
                
                if users.count == 1 {
                    userNames = users[0].name
                } else if users.count == 2 {
                    userNames = "\(users[0].name) and \(users[1].name)"
                } else if users.count > 2 {
                    userNames = "\(users[0].name) and \(users.count - 1) others"
                }
                
                self?.onlinelabel.text = "Online: \(userNames)"
            })
            .disposed(by: disposeBag)
    }
}
