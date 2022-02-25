//
//  ChatBaseVC.swift
//  StreamChat
//
//  Created by Jitendra Sharma on 10/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public class ChatBaseVC: UIViewController {
    @IBOutlet weak var btnNext: UIButton?
    @IBOutlet weak var btnBack: UIButton?
    @IBOutlet weak var btnAddFriend: UIButton?
    @IBOutlet weak var btnInviteLink: UIButton?
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.btnBack?.setTitle("", for: .normal)
        self.btnNext?.setTitle("", for: .normal)
        self.btnAddFriend?.setTitle("", for: .normal)
        self.btnInviteLink?.setTitle("", for: .normal)
        self.btnBack?.setImage(UIImage(named: "backSheet"), for: .normal)
    }
}
