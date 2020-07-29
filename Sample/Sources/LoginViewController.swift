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
import StreamChatClient
import RxGesture

final class LoginViewController: ViewController {
    
    @IBOutlet weak var apiKeyLabel: UITextField!
    @IBOutlet weak var userIdLabel: UITextField!
    @IBOutlet weak var userNameLabel: UITextField!
    @IBOutlet weak var tokenLabel: UITextView!  
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    let userDefaults = UserDefaults()
    var loggedInToken: Token?
    var loggedInUser: StreamChatClient.User?
    var secondUser: StreamChatClient.User?
    let disposeBag = DisposeBag()
    var clientSetupped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.text = "Demo Project\nStream Swift SDK v.\(Environment.version)"
        
        let autoLogin = storedValue(key: .apiKey) != nil
        apiKeyLabel.text = storedValue(key: .apiKey, default: "qk4nn7rpcn75")
        userIdLabel.text = storedValue(key: .userId, default: User.user1.id)
        userNameLabel.text = storedValue(key: .userName, default: User.user1.name)
        tokenLabel.text = storedValue(key: .token, default: Token.token1)
        
        if autoLogin {
            DispatchQueue.main.async { self.login(animated: false) }
        }
        
        setupUsers()
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
        tokenLabel.text = "guest"
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
            apiKeyLabel.placeholder = " ⚠️ Stream Chat API key"
            return
        }
        
        guard let userId = userIdLabel.text, !userId.isBlank else {
            userIdLabel.placeholder = " ⚠️ User id"
            return
        }
        
        guard let userName = userNameLabel.text, !userName.isBlank else {
            userNameLabel.placeholder = " ⚠️ User name"
            return
        }
        
        guard let token = tokenLabel.text, (token == "guest" || token.isValidToken(userId: userId)) else {
            tokenLabel.textColor = .systemRed
            return
        }
        
        store(key: .userId, value: userId)
        store(key: .userName, value: userName)
        store(key: .token, value: token)
        
        let user = User(id: userId)
        user.name = userName
        loggedInUser = user
        loggedInToken = token
        
        if !clientSetupped {
            let config = Client.Config(apiKey: apiKey, baseURL: .usEast, logOptions: .info)
            Client.configureShared(config)

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
        guard let user = loggedInUser, let token = loggedInToken else {
            return
        }
        
        func showNext(_ result: Result<UserConnection, ClientError>) {
            loginButton.isEnabled = true
            
            if let error = result.error {
                show(errorMessage: error.localizedDescription)
            } else if showNextViewController {
                showRootViewController(animated: animated)
            }
        }
        
        loginButton.isEnabled = false
        
        if token == "guest" {
            Client.shared.setGuestUser(user, showNext)
        } else {
            Client.shared.set(user: user, token: token, showNext)
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
    
    private func setupUsers() {
        versionLabel.isUserInteractionEnabled = true
        
        versionLabel.rx.longPressGesture()
            .when(.began)
            .subscribe(onNext: { [unowned self] _ in self.showUsers() })
            .disposed(by: disposeBag)
    }
    
    private func showUsers() {
        let alert = UIAlertController(title: "Select a user", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(.init(title: User.user1.name, style: .default, handler: { [unowned self] _ in
            self.login(with: User.user1, token: .token1)
        }))
        
        alert.addAction(.init(title: User.user2.name, style: .default, handler: { [unowned self] _ in
            self.login(with: User.user2, token: .token2)
        }))
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func login(with user: User, token: Token) {
        userIdLabel.text = user.id
        userNameLabel.text = user.name
        tokenLabel.text = token
        login(animated: true)
    }
}

// MARK: Test Users

extension User {
    static let user1 = User(id: "broken-waterfall-5")
    static let user2 = User(id: "steep-moon-9")
}

extension Token {
    static let token1 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
    static let token2 = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoic3RlZXAtbW9vbi05In0.K7uZEqKmiVb5_Y7XFCmlz64SzOV34hoMpeqRSz7g4YI"
}

// MARK: UserDefaults

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
