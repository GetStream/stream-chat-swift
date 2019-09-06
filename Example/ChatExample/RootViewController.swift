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
    let disposeBag = DisposeBag()
    let channel = Channel(id: "general")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        channel.unreadCount
            .drive(onNext: { [weak self] count in
                self?.badgeLabel.isHidden = count == 0
                self?.badgeLabel.text = String(count)
                UIApplication.shared.applicationIconBadgeNumber = count
            })
            .disposed(by: disposeBag)
    }
}
