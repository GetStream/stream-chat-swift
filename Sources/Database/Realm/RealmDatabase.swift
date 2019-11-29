//
//  RealmDatabase.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 19/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import StreamChatCore
import RealmSwift
import KeychainAccess

/// A Realm datase for Stream Chat.
public final class RealmDatabase {
    
    /// A config for Realm database.
    public static var config = Config(basePath: .caches)
    /// A shared instance.
    public static let shared = RealmDatabase()
    
    private static let schemaVersion: UInt64 = 0
    
    private static let objectTypes: [Object.Type] = [UserRealmObject.self,
                                                     ChannelRealmObject.self,
                                                     ChannelRealmObject.ConfigRealmObject.self,
                                                     ChannelRealmObject.CommandRealmObject.self,
                                                     MemberRealmObject.self,
                                                     MutedUserRealmObject.self,
                                                     MessageRealmObject.self,
                                                     ReactionRealmObject.self,
                                                     ReactionCountsRealmObject.self,
                                                     AttachmentRealmObject.self,
                                                     AttachmentRealmObject.ActionRealmObject.self,
                                                     AttachmentFileRealmObject.self]
    
    /// Setup an optimization for Realm database size (totalBytes > 50Mb, usedBytes < 50%).
    private static let compactOnLaunch = { (totalBytes: Int, usedBytes: Int) -> Bool in
        totalBytes > 0 ? ((totalBytes > 50 * 1024 * 1024) && (Double(usedBytes) / Double(totalBytes)) < 0.5) : false
    }
    
    let basePath: BasePath?
    let keychainServiceId: String?
    let inMemoryId: String?
    public let logger: ClientLogger?
    
    private(set) var realmConfiguration: Realm.Configuration?
    
    /// Setup Keychain service.
    static let keychain = setupKeychain()
    
    var realmURL: URL? {
        return realmConfiguration?.fileURL
    }
    
    public var user: User? {
        didSet {
            do {
                try setup()
            } catch {
                logger?.log(error)
            }
        }
    }
    
    private init(basePath: BasePath = RealmDatabase.config.basePath,
                 keychainServiceId: String? = RealmDatabase.config.keychainServiceId,
                 inMemoryId: String? = RealmDatabase.config.inMemoryId,
                 logOptions: ClientLogger.Options = RealmDatabase.config.logOptions) {
        self.basePath = basePath
        self.keychainServiceId = keychainServiceId
        self.inMemoryId = inMemoryId
        logger = logOptions.logger(icon: "🔮", for: [.databaseError, .database, .databaseInfo])
        logger?.log("Schema version: \(RealmDatabase.schemaVersion)")
    }
    
    static func setupKeychain() -> Keychain {
        return Keychain(service: {
            if let keychainServiceId = RealmDatabase.shared.keychainServiceId {
                return keychainServiceId
            }
            
            if let bundleName = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String, !bundleName.isBlank {
                return bundleName
            }
            
            return "io.getstream.StreamChat"
        }())
    }
}

// MARK: - Setup

extension RealmDatabase {
    private func setup() throws {
        realmConfiguration = nil
        
        guard let user = user, let basePath = basePath else {
            return
        }
        
        let userKey = user.id.appending("57r34mch47").md5
        
        // Setup Realm URL.
        var realmURL = try URL.baseRealmURL(basePath, subPath: userKey)
        realmURL = realmURL.appendingPathComponent("chat").appendingPathExtension("realm")
        logger?.log(realmURL.absoluteString)
        
        // Setup encryption key.
        let encryptionKey: Data = try Data.encryptionKey(userKey: userKey)
        logger?.log("🔑 Encryption key: \(encryptionKey.hex)")
        
        realmConfiguration = Realm.Configuration(fileURL: realmURL,
                                                 inMemoryIdentifier: inMemoryId,
                                                 encryptionKey: encryptionKey,
                                                 schemaVersion: RealmDatabase.schemaVersion,
                                                 migrationBlock: nil,
                                                 deleteRealmIfMigrationNeeded: false,
                                                 shouldCompactOnLaunch: RealmDatabase.compactOnLaunch,
                                                 objectTypes: RealmDatabase.objectTypes)
    }
}

public extension RealmDatabase {
    struct Config {
        public let basePath: BasePath
        public let keychainServiceId: String?
        public let inMemoryId: String?
        public let logOptions: ClientLogger.Options
        
        public init(basePath: BasePath,
                    keychainServiceId: String? = nil,
                    inMemoryId: String? = nil,
                    logOptions: ClientLogger.Options = []) {
            self.basePath = basePath
            self.keychainServiceId = keychainServiceId
            self.inMemoryId = inMemoryId
            self.logOptions = logOptions
        }
    }
    
    enum BasePath {
        case caches, document
        
        var path: String? {
            let pathDirectory: FileManager.SearchPathDirectory
            
            switch self {
            case .caches: pathDirectory = .cachesDirectory
            case .document: pathDirectory = .documentDirectory
            }
            
            return NSSearchPathForDirectoriesInDomains(pathDirectory, .userDomainMask, true).first
        }
    }
    
    enum Error: Swift.Error {
        case userDataInvalid
        case documentsPathFailed
        case generatingKeyDataFailed
    }
}
