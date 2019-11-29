//
//  String+Extensions.swift
//  StreamChatRealm
//
//  Created by Alexey Bukhtin on 28/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import CommonCrypto

extension String {
    static let dataToHEXFormat = "%02hhx"
    private static let fileNameCharacterSet = CharacterSet.lowercaseLetters.union(.decimalDigits).union(.init(charactersIn: "_"))
    
    var md5: String {
        let context = UnsafeMutablePointer<CC_MD5_CTX>.allocate(capacity: 1)
        var digest = Array<UInt8>(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Init(context)
        CC_MD5_Update(context, self, CC_LONG(lengthOfBytes(using: .utf8)))
        CC_MD5_Final(&digest, context)
        context.deallocate()
        return digest.map({ String(format: String.dataToHEXFormat, $0) }).joined()
    }
    
    var url: URL? {
        return URL(string: self)
    }
    
    var fileName: String {
        var fileName = String(UnicodeScalarView(lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .unicodeScalars
            .lazy
            .filter({ String.fileNameCharacterSet.contains($0) })))
        
        if fileName.count > 20 {
            fileName = String(fileName.prefix(20))
        }
        
        return fileName
    }
}
