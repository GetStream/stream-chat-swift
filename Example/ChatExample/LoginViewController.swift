//
//  LoginViewController.swift
//  ChatExample
//
//  Created by Alexey Bukhtin on 08/10/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore

final class LoginViewController: UIViewController {
    
    @IBOutlet weak var versionLabel: UILabel!
    var loggedInUser: User?
    var loggenInToken: Token?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.text = "Demo Project\nStream Swift SDK v.\(Client.version)"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loggedInUser = nil
        loggenInToken = nil
        Client.shared.disconnect()
    }
    
    @IBAction func login(_ sender: UIButton) {
        if sender.tag == 1 {
            loggedInUser = .user1
            loggenInToken = .token1
        }
        
        if sender.tag == 2 {
            loggedInUser = .user2
            loggenInToken = .token2
        }
        
        if sender.tag == 3 {
            loggedInUser = .user3
            loggenInToken = .token3
        }
        
        login(showNextViewController: true)
    }
    
    func showRootViewController() {
        performSegue(withIdentifier: "RootViewController", sender: self)
    }
    
    func login(showNextViewController: Bool = false) {
        if let user = loggedInUser, let token = loggenInToken {
            Client.shared.set(user: user, token: token)
            
            if showNextViewController {
                showRootViewController()
            }
        }
    }
}
