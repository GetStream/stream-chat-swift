//
//  EndpointProtocol.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 01/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

protocol EndpointProtocol {
    var method: Client.Method { get }
    var path: String { get }
    var parameters: [String: String]? { get }
    var body: Encodable? { get }
    var bodyEncoder: JSONEncoder { get }
}

extension EndpointProtocol {
    
    var parameters: [String: String]? {
        return nil
    }
    
    var body: Encodable? {
        return nil
    }
    
    var bodyEncoder: JSONEncoder {
        return JSONEncoder()
    }
}
