//
//  ULID.swift
//  ULID
//
//  Created by Yasuhiro Hatta on 2019/01/11.
//  Copyright © 2019 yaslab. All rights reserved.
//

import Foundation

typealias ulid_t = uuid_t

struct ULID: Hashable, Equatable, Comparable, CustomStringConvertible {

    private(set) var ulid: ulid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

    init(ulid: ulid_t) {
        self.ulid = ulid
    }

    init?(ulidData data: Data) {
        guard data.count == 16 else {
            return nil
        }
        withUnsafeMutableBytes(of: &ulid) {
            $0.copyBytes(from: data)
        }
    }

    init?(ulidString string: String) {
        guard string.utf8.count == 26, let data = Data(base32Encoded: "000000" + string) else {
            return nil
        }
        withUnsafeMutableBytes(of: &ulid) {
            $0.copyBytes(from: data.dropFirst(4))
        }
    }
    
    /// Creates a new ULID instance from a given timestamp and a random part that you provide
    /// - Parameters:
    ///   - timestamp: -
    ///   - randomPartData: Data representation of the random part of the ULID
    /// - Returns: **NIL** if the `randomPartData` is less than 80 bits or 10 bytes in size
    init?(timestamp: Date = Date(), randomPartData data: Data){
        let randomDataInBytes = 10
        guard data.count >= randomDataInBytes else { return nil }
        
        withUnsafeMutableBytes(of: &ulid) { (buffer) in
            var i = 0
            var millisec = UInt64(timestamp.timeIntervalSince1970 * 1000.0).bigEndian
            withUnsafeBytes(of: &millisec) {
                for j in 2 ..< 8 {
                    buffer[i] = $0[j]
                    i += 1
                }
            }
            var randomPart:Data = Data()
            if data.count > randomDataInBytes{
                randomPart = data.prefix(randomDataInBytes)
            }else{
                randomPart = data
            }
            
            withUnsafeBytes(of: &randomPart) {
                for j in 0 ..< 10 {
                    buffer[i] = $0[j]
                    i += 1
                }
            }
        }
    }

    init<T: RandomNumberGenerator>(timestamp: Date, generator: inout T) {
        withUnsafeMutableBytes(of: &ulid) { (buffer) in
            var i = 0
            var millisec = UInt64(timestamp.timeIntervalSince1970 * 1000.0).bigEndian
            withUnsafeBytes(of: &millisec) {
                for j in 2 ..< 8 {
                    buffer[i] = $0[j]
                    i += 1
                }
            }
            var random16 = UInt16.random(in: .min ... .max, using: &generator).bigEndian
            withUnsafeBytes(of: &random16) {
                for j in 0 ..< 2 {
                    buffer[i] = $0[j]
                    i += 1
                }
            }
            var random64 = UInt64.random(in: .min ... .max, using: &generator).bigEndian
            withUnsafeBytes(of: &random64) {
                for j in 0 ..< 8 {
                    buffer[i] = $0[j]
                    i += 1
                }
            }
        }
    }

    init(timestamp: Date = Date()) {
        var g = SystemRandomNumberGenerator()
        self.init(timestamp: timestamp, generator: &g)
    }

    var ulidData: Data {
        return withUnsafeBytes(of: ulid) {
            return Data(buffer: $0.bindMemory(to: UInt8.self))
        }
    }

    var ulidString: String {
        return withUnsafeBytes(of: ulid) {
            var data = Data(count: 4)
            data.append($0.bindMemory(to: UInt8.self))
            return String(data.base32EncodedString().dropFirst(6))
        }
    }

    var timestamp: Date {
        return withUnsafeBytes(of: ulid) { (buffer) in
            var millisec: UInt64 = 0
            withUnsafeMutableBytes(of: &millisec) {
                for i in 0 ..< 6 {
                    $0[2 + i] = buffer[i]
                }
            }
            return Date(timeIntervalSince1970: TimeInterval(millisec.bigEndian) / 1000.0)
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ulid.0)
        hasher.combine(ulid.1)
        hasher.combine(ulid.2)
        hasher.combine(ulid.3)
        hasher.combine(ulid.4)
        hasher.combine(ulid.5)
        hasher.combine(ulid.6)
        hasher.combine(ulid.7)
        hasher.combine(ulid.8)
        hasher.combine(ulid.9)
        hasher.combine(ulid.10)
        hasher.combine(ulid.11)
        hasher.combine(ulid.12)
        hasher.combine(ulid.13)
        hasher.combine(ulid.14)
        hasher.combine(ulid.15)
    }

    static func == (lhs: ULID, rhs: ULID) -> Bool {
        return lhs.ulid.0 == rhs.ulid.0
            && lhs.ulid.1 == rhs.ulid.1
            && lhs.ulid.2 == rhs.ulid.2
            && lhs.ulid.3 == rhs.ulid.3
            && lhs.ulid.4 == rhs.ulid.4
            && lhs.ulid.5 == rhs.ulid.5
            && lhs.ulid.6 == rhs.ulid.6
            && lhs.ulid.7 == rhs.ulid.7
            && lhs.ulid.8 == rhs.ulid.8
            && lhs.ulid.9 == rhs.ulid.9
            && lhs.ulid.10 == rhs.ulid.10
            && lhs.ulid.11 == rhs.ulid.11
            && lhs.ulid.12 == rhs.ulid.12
            && lhs.ulid.13 == rhs.ulid.13
            && lhs.ulid.14 == rhs.ulid.14
            && lhs.ulid.15 == rhs.ulid.15
    }

    static func < (lhs: ULID, rhs: ULID) -> Bool {
        if lhs.ulid.0 != rhs.ulid.0 { return lhs.ulid.0 < rhs.ulid.0 }
        if lhs.ulid.1 != rhs.ulid.1 { return lhs.ulid.1 < rhs.ulid.1 }
        if lhs.ulid.2 != rhs.ulid.2 { return lhs.ulid.2 < rhs.ulid.2 }
        if lhs.ulid.3 != rhs.ulid.3 { return lhs.ulid.3 < rhs.ulid.3 }
        if lhs.ulid.4 != rhs.ulid.4 { return lhs.ulid.4 < rhs.ulid.4 }
        if lhs.ulid.5 != rhs.ulid.5 { return lhs.ulid.5 < rhs.ulid.5 }
        if lhs.ulid.6 != rhs.ulid.6 { return lhs.ulid.6 < rhs.ulid.6 }
        if lhs.ulid.7 != rhs.ulid.7 { return lhs.ulid.7 < rhs.ulid.7 }
        if lhs.ulid.8 != rhs.ulid.8 { return lhs.ulid.8 < rhs.ulid.8 }
        if lhs.ulid.9 != rhs.ulid.9 { return lhs.ulid.9 < rhs.ulid.9 }
        if lhs.ulid.10 != rhs.ulid.10 { return lhs.ulid.10 < rhs.ulid.10 }
        if lhs.ulid.11 != rhs.ulid.11 { return lhs.ulid.11 < rhs.ulid.11 }
        if lhs.ulid.12 != rhs.ulid.12 { return lhs.ulid.12 < rhs.ulid.12 }
        if lhs.ulid.13 != rhs.ulid.13 { return lhs.ulid.13 < rhs.ulid.13 }
        if lhs.ulid.14 != rhs.ulid.14 { return lhs.ulid.14 < rhs.ulid.14 }
        return lhs.ulid.15 < rhs.ulid.15
    }

    var description: String {
        return ulidString
    }

}

extension ULID: Codable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let ulid = ULID(ulidString: string) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                    debugDescription: "Attempted to decode ULID from invalid ULID string."))
        }

        self = ulid
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.ulidString)
    }

}
