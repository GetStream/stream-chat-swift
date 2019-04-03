//
//  CustomChannel.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// This is an example of a custom Channel with custom properties.

//final class CustomChannel: Channel {
//    public enum CodingKeys: String, CodingKey {
//        case customProperty = "custom_property"
//    }
//
//    var customProperty = 123
//
//    required public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        customProperty = try container.decode(Int.self, forKey: .customProperty)
//        try super.init(from: decoder)
//    }
//
//    override func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(customProperty, forKey: .customProperty)
//        try super.encode(to: encoder)
//    }
//}
