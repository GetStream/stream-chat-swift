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
        
        let autoLogin = storedValue(key: .apiKey) != nil
        apiKeyLabel.text = storedValue(key: .apiKey, default: "qk4nn7rpcn75")
        userIdLabel.text = storedValue(key: .userId, default: "broken-waterfall-5")
        userNameLabel.text = storedValue(key: .userName, default: "Broken waterfall")
        tokenLabel.text = storedValue(key: .token, default:  "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg")
        
        if autoLogin {
            DispatchQueue.main.async { self.login(animated: false) }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loggedInUser = nil
        loggedInToken = nil
        
        if clientSetupped {
            apiKeyLabel.isEnabled = false
            apiKeyLabel.textColor = .systemGray
            remove(key: .apiKey)
            remove(key: .userId)
            remove(key: .userName)
            remove(key: .token)
            Client.shared.disconnect()
            let info = "(restart the app to change it)"
            
            if !(apiKeyLabel.text ?? "").contains(info) {
                apiKeyLabel.text = "\(apiKeyLabel.text ?? "") \(info)"
            }
        } else if (apiKeyLabel.text ?? "").isEmpty {
            apiKeyLabel.becomeFirstResponder()
        }
    }
    
    @IBAction func guestToken(_ sender: Any) {
        tokenLabel.text = Token.guest
    }
    
    @IBAction func developmentToken(_ sender: Any) {
        tokenLabel.text = Token.development
    }
    
    @IBAction func login(_ sender: Any) {
        login(animated: true)
    }
    
    func login(animated: Bool) {
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
        
        store(key: .userId, value: userId)
        store(key: .userName, value: userName)
        store(key: .token, value: token)
        
        loggedInUser = User(id: userId, name: userName)
        loggedInToken = token
        
        if !clientSetupped {
            Client.config = .init(apiKey: apiKey,
//                                  baseURL: .init(customURL: URL(string: "https://chat-proxy-us-east.stream-io-api.com/")!),
                                  database: Database.instance,
                                  logOptions: .info)
            
            Notifications.shared.clearApplicationIconBadgeNumberOnAppActive = true
            store(key: .apiKey, value: apiKey)
            clientSetupped = true
        }
        
        login(showNextViewController: true, animated: animated)
    }
    
    func showRootViewController(animated: Bool) {
        performSegue(withIdentifier: animated ? "RootAnimated" : "Root", sender: self)
    }
    
    func login(showNextViewController: Bool = false, animated: Bool) {
        if let user = loggedInUser, let token = loggedInToken {
            Client.shared.set(user: user, token: token)
            
            if showNextViewController {
                showRootViewController(animated: animated)
            }
        }
    }
    
    @IBAction func clear(_ sender: Any) {
        userIdLabel.text = nil
        userNameLabel.text = nil
        tokenLabel.text = nil
        
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
        case apiKey, userId, userName, token
    }
    
    func store(key: StoreKey, value: String) {
        userDefaults.set(value, forKey: key.rawValue)
        userDefaults.synchronize()
    }
    
    func storedValue(key: StoreKey, default: String? = nil) -> String? {
        return (userDefaults.value(forKey: key.rawValue) as? String) ?? `default`
    }
    
    func remove(key: StoreKey) {
        userDefaults.removeObject(forKey: key.rawValue)
        userDefaults.synchronize()
    }
}
