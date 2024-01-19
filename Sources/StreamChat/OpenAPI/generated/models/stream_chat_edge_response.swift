//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEdgeResponse: Codable, Hashable {
    public var countryIsoCode: String
    
    public var green: Int
    
    public var id: String
    
    public var latitude: Double
    
    public var subdivisionIsoCode: String
    
    public var yellow: Int
    
    public var continentCode: String
    
    public var longitude: Double
    
    public var red: Int
    
    public var latencyTestUrl: String
    
    public init(countryIsoCode: String, green: Int, id: String, latitude: Double, subdivisionIsoCode: String, yellow: Int, continentCode: String, longitude: Double, red: Int, latencyTestUrl: String) {
        self.countryIsoCode = countryIsoCode
        
        self.green = green
        
        self.id = id
        
        self.latitude = latitude
        
        self.subdivisionIsoCode = subdivisionIsoCode
        
        self.yellow = yellow
        
        self.continentCode = continentCode
        
        self.longitude = longitude
        
        self.red = red
        
        self.latencyTestUrl = latencyTestUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case countryIsoCode = "country_iso_code"
        
        case green
        
        case id
        
        case latitude
        
        case subdivisionIsoCode = "subdivision_iso_code"
        
        case yellow
        
        case continentCode = "continent_code"
        
        case longitude
        
        case red
        
        case latencyTestUrl = "latency_test_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(countryIsoCode, forKey: .countryIsoCode)
        
        try container.encode(green, forKey: .green)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(latitude, forKey: .latitude)
        
        try container.encode(subdivisionIsoCode, forKey: .subdivisionIsoCode)
        
        try container.encode(yellow, forKey: .yellow)
        
        try container.encode(continentCode, forKey: .continentCode)
        
        try container.encode(longitude, forKey: .longitude)
        
        try container.encode(red, forKey: .red)
        
        try container.encode(latencyTestUrl, forKey: .latencyTestUrl)
    }
}
