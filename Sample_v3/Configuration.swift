//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient

struct Configuration {
    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: "apiKey") ?? "qk4nn7rpcn75" }
        set { UserDefaults.standard.setValue(newValue, forKey: "apiKey") }
    }
    
    static var userId: String {
        get { UserDefaults.standard.string(forKey: "userId") ?? "broken-waterfall-5" }
        set { UserDefaults.standard.setValue(newValue, forKey: "userId") }
    }
    
    static var userName: String {
        get { UserDefaults.standard.string(forKey: "userName") ?? "Broken Waterfall" }
        set { UserDefaults.standard.setValue(newValue, forKey: "userName") }
    }
    
    static var baseURL: BaseURL {
        get {
            guard
                let string = UserDefaults.standard.string(forKey: "baseURL"),
                let url = URL(string: string)
            else {
                return .usEast
            }
            
            return BaseURL(url: url)
        }
        set { UserDefaults.standard.setValue(newValue.description, forKey: "baseURL") }
    }

    static var token: Token? {
        get {
            UserDefaults.standard
                .string(forKey: "token") ??
                "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
        }
        set { UserDefaults.standard.setValue(newValue, forKey: "token") }
    }
    
    static var isLocalStorageEnabled: Bool {
        get { UserDefaults.standard.value(forKey: "isLocalStorageEnabled") as? Bool ?? true }
        set { UserDefaults.standard.setValue(newValue, forKey: "isLocalStorageEnabled") }
    }
    
    static var shouldFlushLocalStorageOnStart: Bool {
        get { UserDefaults.standard.value(forKey: "shouldFlushLocalStorageOnStart") as? Bool ?? false }
        set { UserDefaults.standard.setValue(newValue, forKey: "shouldFlushLocalStorageOnStart") }
    }
}
