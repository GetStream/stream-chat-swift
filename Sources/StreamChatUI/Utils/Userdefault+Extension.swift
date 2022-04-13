//
//  Userdefault+Extension.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 31/03/22.
//

import Foundation

public extension UserDefaults {
    public func save<T:Encodable>(customObject object: T, inKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            self.set(encoded, forKey: key)
        }
    }

    public func retrieve<T:Decodable>(object type:T.Type, fromKey key: String) -> T? {
        if let data = self.data(forKey: key) {
            let decoder = JSONDecoder()
            if let object = try? decoder.decode(type, from: data) {
                return object
            }else {
                return nil
            }
        }else {
            return nil
        }
    }

}
