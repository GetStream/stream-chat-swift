//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

enum Configuration {
    enum PersistenceKeys {
        static let apiKey = "apiKey"
        static let userId = "userId"
        static let userName = "userName"
        static let baseURL = "baseURL"
        static let token = "token"
        static let isLocalStorageEnabled = "isLocalStorageEnabled"
        static let shouldFlushLocalStorageOnStart = "shouldFlushLocalStorageOnStart"
    }
    
    enum DefaultValues {
        static let apiKey = "8br4watad788"
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
        let token: Token
        
        static var defaults: [Self] {
            [
                TestUser(
                    name: "Luke Skywalker",
                    id: "luke_skywalker",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibHVrZV9za3l3YWxrZXIifQ.kFSLHRB5X62t0Zlc7nwczWUfsQMwfkpylC6jCUZ6Mc0"
                ),
                
                TestUser(
                    name: "Leia Organa",
                    id: "leia_organa",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGVpYV9vcmdhbmEifQ.IzwBuaYwX5dRvnDDnJN2AyW3wwfYwgQm3w-1RD4BLPU"
                ),
                
                TestUser(
                    name: "Han Solo",
                    id: "han_solo",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiaGFuX3NvbG8ifQ.R6PkQeGPcusALmhvaST50lwroL_JkZnI3Q7hQ1Hvj3k"
                ),
                
                TestUser(
                    name: "Lando Calrissian",
                    id: "lando_calrissian",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibGFuZG9fY2Fscmlzc2lhbiJ9.n_K7d-FroQzBUxETNcEQYqiW_U9CPjRHZHT1hyAjlAQ"
                ),
                
                TestUser(
                    name: "Chewbacca",
                    id: "chewbacca",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2hld2JhY2NhIn0.4nNFfO0dehvdLxDUGaMQPpMliSTGjHqh1C2Zo8wyaeM"
                ),
                
                TestUser(
                    name: "C-3PO",
                    id: "c-3po",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYy0zcG8ifQ.J4Xzu8rKP1XWQvSNV6wzWKW403qKd5N3FalpWXTDauw"
                ),
                
                TestUser(
                    name: "R2-D2",
                    id: "r2-d2",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicjItZDIifQ.UpSEW8jA2tYsUTPKbdFGMtHHnu9_AnEQqTK6TdT8L1g"
                ),
                
                TestUser(
                    name: "Anakin Skywalker",
                    id: "anakin_skywalker",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiYW5ha2luX3NreXdhbGtlciJ9.oJkwakjdqw6gCA3-kaUaKqSVEcWO5ob5DJuyJCtnT6U"
                ),
                
                TestUser(
                    name: "Obi-Wan Kenobi",
                    id: "obi-wan_kenobi",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoib2JpLXdhbl9rZW5vYmkifQ.AVOtnXtMq9crXFwl68BrBRob335phYpYfPPq5i2agUM"
                ),
                
                TestUser(
                    name: "Padme Amidala",
                    id: "padme_amidala",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicGFkbWVfYW1pZGFsYSJ9.X8CwsnrWKvdrS6XchcUMZDLh_W0X4Gpx-oNyjGAdenI"
                ),
                
                TestUser(
                    name: "Qui-Gon Jinn",
                    id: "qui-gon_jinn",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoicXVpLWdvbl9qaW5uIn0.EDuyuTkyzG1OA3ROwa3sK8-K_U2MGREsY4Ic7flXvzw"
                ),
                
                TestUser(
                    name: "Mace Windu",
                    id: "mace_windu",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoibWFjZV93aW5kdSJ9.x8xFcOQFr0XUDeA3BH0ISsR2VSmWSxmMgbnz8lprV58"
                ),
                
                TestUser(
                    name: "Jar Jar Binks",
                    id: "jar_jar_binks",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiamFyX2phcl9iaW5rcyJ9.5-GhGE8sqlxKNUMyBGovrkoaxgkEQAUMJ3CZfcxyrZg"
                ),
                
                TestUser(
                    name: "Darth Maul",
                    id: "darth_maul",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZGFydGhfbWF1bCJ9._cbBA2ThWpXcyxwvBV6gvqAwnw0lvzfHAlZ4stGqf2o"
                ),
                
                TestUser(
                    name: "Count Dooku",
                    id: "count_dooku",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY291bnRfZG9va3UifQ.0sN_cPTKrXsxC23WUSIBUQK5IUZsdGijmqY50HJERQw"
                ),
                
                TestUser(
                    name: "General Grievous",
                    id: "general_grievous",
                    token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZ2VuZXJhbF9ncmlldm91cyJ9.FPRvRoeZdALErBA1bDybch4xY-c5CEinuc9qqEPzX4E"
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
        get {
            guard
                let rawValue = UserDefaults.standard.string(forKey: PersistenceKeys.token),
                let token = try? Token(rawValue: rawValue)
            else {
                return DefaultValues.token
            }

            return token
        }
        set { UserDefaults.standard.setValue(newValue?.rawValue, forKey: PersistenceKeys.token) }
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
