//
//  Realm+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 28/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RealmSwift

extension Realm {
    static var `default`: Realm? {
        guard let realmConfiguration = RealmDatabase.shared.realmConfiguration else {
            return nil
        }
        
        do {
            return try Realm(configuration: realmConfiguration)
        } catch let error as Realm.Error {
            RealmDatabase.shared.logger?.log(error, message: "Getting the default Realm")
            
            if error.code == .fileAccess || error.code == .schemaMismatch {
                RealmDatabase.shared.logger?.log("Trying to clean up the Realm database...")
                
                if let realmURL = RealmDatabase.shared.realmURL {
                    do {
                        var realmURL = realmURL
                        realmURL.deleteLastPathComponent()
                        
                        if FileManager.default.fileExists(atPath: realmURL.path) {
                            try FileManager.default.removeItem(at: realmURL)
                            try RealmDatabase.shared.setup()
                        } else {
                            return nil
                        }
                    } catch let error {
                        RealmDatabase.shared.logger?.log(error, message: "Cleaning up Realm directory")
                        return nil
                    }
                }
                
                return Realm.default
                
            } else {
                RealmDatabase.shared.logger?.log(error)
                return nil
            }
        } catch let error {
            RealmDatabase.shared.logger?.log(error)
            return nil
        }
    }
    
    @discardableResult
    func write(orCatchError errorContext: String = "",
               function: String = #function,
               line: Int = #line,
               _ transaction: (_ realm: Realm) -> Void) -> Bool {
        refresh()
        
        do {
            try write { transaction(self) }
            return true
        } catch let error {
            RealmDatabase.shared.logger?.log(error, message: errorContext)
            return false
        }
    }
}
