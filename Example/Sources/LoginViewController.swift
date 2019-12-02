//
//  LoginViewController.swift
//  ChatExample
//
//  Created by Alexey Bukhtin on 08/10/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import StreamChat
import StreamChatCore

final class LoginViewController: UIViewController {
    
    @IBOutlet weak var apiKeyLabel: UITextField!
    @IBOutlet weak var userIdLabel: UITextField!
    @IBOutlet weak var userNameLabel: UITextField!
    @IBOutlet weak var tokenLabel: UITextView!
    @IBOutlet weak var secondUserIdLabel: UITextField!
    @IBOutlet weak var versionLabel: UILabel!
    let userDefaults = UserDefaults()
    var loggedInToken: Token?
    var loggedInUser: StreamChatCore.User?
    var secondUser: StreamChatCore.User?
    let disposeBag = DisposeBag()
    var clientSetupped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.text = "Demo Project\nStream Swift SDK v.\(Client.version)"
        
        apiKeyLabel.text = storedValue(key: .apiKey, default: "qk4nn7rpcn75")
        userIdLabel.text = storedValue(key: .userId, default: "broken-waterfall-5")
        userNameLabel.text = storedValue(key: .userName, default: "Broken waterfall")
        tokenLabel.text = storedValue(key: .token, default:  "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg")
        secondUserIdLabel.text = storedValue(key: .secondUserId)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loggedInUser = nil
        loggedInToken = nil
        
        if clientSetupped {
            apiKeyLabel.isEnabled = false
            apiKeyLabel.textColor = .systemGray
            apiKeyLabel.text = "\(apiKeyLabel.text ?? "") (restart the app to change it)"
            Client.shared.disconnect()
        } else if (apiKeyLabel.text ?? "").isEmpty {
            apiKeyLabel.becomeFirstResponder()
        }
    }
    
    @IBAction func login(_ sender: Any) {
        if #available(iOS 13.0, *) {
            tokenLabel.textColor = .label
        } else {
            tokenLabel.textColor = .black
        }
        
        guard let apiKey = apiKeyLabel.text, !apiKey.isBlank else {
            apiKeyLabel.placeholder = "⚠️ Stream Chat API key"
            return
        }
        
        guard let userId = userIdLabel.text, !userId.isBlank else {
            userIdLabel.placeholder = "⚠️ User id"
            return
        }
        
        guard let userName = userNameLabel.text, !userName.isBlank else {
            userNameLabel.placeholder = "⚠️ User name"
            return
        }
        
        guard let token = tokenLabel.text, token.isValidToken(userId: userId) else {
            tokenLabel.textColor = .systemRed
            return
        }
        
        store(key: .apiKey, value: apiKey)
        store(key: .userId, value: userId)
        store(key: .userName, value: userName)
        store(key: .token, value: token)
        
        if let secondUserId = secondUserIdLabel.text {
            secondUser = User(id: secondUserId, name: secondUserId)
            store(key: .secondUserId, value: secondUserId)
        }
        
        loggedInUser = User(id: userId, name: userName)
        loggedInToken = token
        
        if !clientSetupped {
            Client.config = .init(apiKey: apiKey,
                                  logOptions: .debug)
            
            Notifications.shared.clearApplicationIconBadgeNumberOnAppActive = true
            clientSetupped = true
        }
        
        login(showNextViewController: true)
    }
    
    func showRootViewController() {
        performSegue(withIdentifier: "RootViewController", sender: self)
    }
    
    func login(showNextViewController: Bool = false) {
        if let user = loggedInUser, let token = loggedInToken {
            Client.shared.set(user: user, token: token)
            
            if showNextViewController {
                showRootViewController()
            }
        }
    }
    
    @IBAction func clear(_ sender: Any) {
        userIdLabel.text = nil
        userNameLabel.text = nil
        tokenLabel.text = nil
        secondUserIdLabel.text = nil
        
        if clientSetupped {
            userIdLabel.becomeFirstResponder()
        } else {
            apiKeyLabel.text = nil
            apiKeyLabel.becomeFirstResponder()
        }
    }
}

// MARk: UserDefaults

extension LoginViewController {
    enum StoreKey: String {
        case apiKey, userId, userName, token, secondUserId
    }
    
    func store(key: StoreKey, value: String) {
        userDefaults.set(value, forKey: key.rawValue)
    }
    
    func storedValue(key: StoreKey, default: String? = nil) -> String? {
        return (userDefaults.value(forKey: key.rawValue) as? String) ?? `default`
    }
}
