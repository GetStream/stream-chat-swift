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
    var queryItem: Encodable? { get }
    var queryItems: [String: Encodable]? { get }
    var body: Encodable? { get }
}

extension EndpointProtocol {
    
    var queryItem: Encodable? {
        return nil
    }
    
    var queryItems: [String: Encodable]? {
        return nil
    }
    
    var body: Encodable? {
        return nil
    }
}
