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
import RxGesture

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
                                  baseURL: .init(serverLocation: .proxyEast),
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
    static let user1 = User(id: "broken-waterfall-5", name: "Jon Snow", avatarURL: URL(string: "https://bit.ly/2u9Vc0r"))
    static let user2 = User(id: "steep-moon-9", name: "Steep moon")
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
