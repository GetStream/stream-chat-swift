//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

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
        static let userId = TestUser.defaults[0].id
        static let userName = TestUser.defaults[0].name
        static let token = TestUser.defaults[0].token
        static let baseURL = BaseURL.usEast
        static let isLocalStorageEnabled = true
        static let shouldFlushLocalStorageOnStart = false
    }
    
    struct TestUser {
        let name: String
        let id: String
        let token: String
        
        static var defaults: [Self] {
            [
                TestUser(
                    name: "Broken Waterfall",
                    id: "broken-waterfall-5",
                    token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
                ),
                TestUser(
                    name: "Suspicious Coyote",
                    id: "suspicious-coyote-3",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic3VzcGljaW91cy1jb3lvdGUtMyJ9.xVaBHFTexlYPEymPmlgIYCM5M_iQVHrygaGS1QhkaEE"
                ),
                TestUser(
                    name: "Steep Moon",
                    id: "steep-moon-9",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic3RlZXAtbW9vbi05In0.xwGjOwnTy3r4o2owevNTyzZLWMsMh_bK7e5s1OQ2zXU"
                )
            ]
        }
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
