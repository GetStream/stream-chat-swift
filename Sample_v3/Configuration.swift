//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient

struct Configuration {
    struct PersistenceKeys {
        static let apiKey = "apiKey"
        static let userId = "userId"
        static let userName = "userName"
        static let baseURL = "baseURL"
        static let token = "token"
        static let isLocalStorageEnabled = "isLocalStorageEnabled"
        static let shouldFlushLocalStorageOnStart = "shouldFlushLocalStorageOnStart"
    }
    
    struct DefaultValues {
        static let apiKey = "qk4nn7rpcn75"
        static let userId = "broken-waterfall-5"
        static let userName = "Broken Waterfall"
        static let baseURL = BaseURL.usEast
        static let token =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
        static let isLocalStorageEnabled = true
        static let shouldFlushLocalStorageOnStart = false
    }
    
    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: PersistenceKeys.apiKey) ?? DefaultValues.apiKey }
        set { UserDefaults.standard.setValue(newValue, forKey: PersistenceKeys.apiKey) }
    }
    
    static var userId: String {
        get { UserDefaults.standard.string(forKey: PersistenceKeys.userId) ?? DefaultValues.userId }
        set { UserDefaults.standard.setValue(newValue, forKey: PersistenceKeys.userId) }
    }
    
    static var userName: String {
        get { UserDefaults.standard.string(forKey: PersistenceKeys.userName) ?? DefaultValues.userName }
        set { UserDefaults.standard.setValue(newValue, forKey: PersistenceKeys.userName) }
    }
    
    static var baseURL: BaseURL {
        get {
            guard
                let string = UserDefaults.standard.string(forKey: PersistenceKeys.baseURL),
                let url = URL(string: string)
            else {
                return DefaultValues.baseURL
            }
            
            return BaseURL(url: url)
        }
        set { UserDefaults.standard.setValue(newValue.description, forKey: PersistenceKeys.baseURL) }
    }

    static var token: Token? {
        get { UserDefaults.standard.string(forKey: "token") ?? DefaultValues.token }
        set { UserDefaults.standard.setValue(newValue, forKey: PersistenceKeys.token) }
    }
    
    static var isLocalStorageEnabled: Bool {
        get {
            UserDefaults.standard.value(forKey: PersistenceKeys.isLocalStorageEnabled) as? Bool ?? DefaultValues
                .isLocalStorageEnabled
        }
        set { UserDefaults.standard.setValue(newValue, forKey: PersistenceKeys.isLocalStorageEnabled) }
    }
    
    static var shouldFlushLocalStorageOnStart: Bool {
        get {
            UserDefaults.standard.value(forKey: PersistenceKeys.shouldFlushLocalStorageOnStart) as? Bool ?? DefaultValues
                .shouldFlushLocalStorageOnStart
        }
        set { UserDefaults.standard.setValue(newValue, forKey: PersistenceKeys.shouldFlushLocalStorageOnStart) }
    }
}
