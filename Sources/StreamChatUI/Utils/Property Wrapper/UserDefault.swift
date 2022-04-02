//
//  UserDefault.swift
//  Timeless-iOS
//
// Created by Brian Sipple on 4/20/20.
// Copyright © 2020 Timeless. All rights reserved.
//

// References
//      - https://github.com/guillermomuntaner/Burritos
//      - https://www.swiftbysundell.com/articles/property-wrappers-in-swift/

import Foundation


/// A type safe property wrapper to set and get values from UserDefaults with support for defaults values.
///
/// Usage:
/// ```
/// @UserDefault("has_seen_app_introduction", defaultValue: false)
/// static var hasSeenAppIntroduction: Bool
/// ```
///
/// [Apple documentation on UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults)
@propertyWrapper
public struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    var userDefaults: UserDefaults


    public init(
        key: String,
        defaultValue: Value,
        storage: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = storage
    }


    public var wrappedValue: Value {
        get {
            return userDefaults.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                userDefaults.removeObject(forKey: key)
            } else {
                userDefaults.setValue(newValue, forKey: key)
            }
        }
    }
}


// MARK: - Allow `defaultValue` of  nil
extension UserDefault where Value: ExpressibleByNilLiteral {
    init(key: String, storage: UserDefaults = .standard) {
        self.init(key: key, defaultValue: nil, storage: storage)
    }
}


@propertyWrapper
public struct UserDefaultCodable<Value: Codable> {
    let key: String
    let defaultValue: Value?
    var userDefaults: UserDefaults

    public init(
        key: String,
        defaultValue: Value?,
        storage: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = storage
    }

    public var wrappedValue: Value? {
        get {
            if let value = userDefaults.data(forKey: key),
               let parsed = try? PropertyListDecoder().decode(Value.self, from: value) {
                return parsed
            }
            return defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                userDefaults.removeObject(forKey: key)
            } else {
                if let parsed = try? PropertyListEncoder().encode(newValue) {
                    userDefaults.setValue(parsed, forKey: key)
                }
            }
        }
    }

    public static func getValue(forKey key: String, in storage: UserDefaults = .standard) -> Value? {
        if let value = storage.data(forKey: key),
           let parsed = try? PropertyListDecoder().decode(Value.self, from: value) {
            return parsed
        }
        return nil
    }
}

// Since our property wrapper's Value type isn't optional, but
// can still contain nil values, we'll have to introduce this
// protocol to enable us to cast any assigned value into a type
// that we can compare against nil:
private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
