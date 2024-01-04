//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEdgeResponse: Codable, Hashable {
    public var continentCode: String
    
    public var id: String
    
    public var latencyTestUrl: String
    
    public var latitude: Double
    
    public var longitude: Double
    
    public var subdivisionIsoCode: String
    
    public var countryIsoCode: String
    
    public var green: Int
    
    public var red: Int
    
    public var yellow: Int
    
    public init(continentCode: String, id: String, latencyTestUrl: String, latitude: Double, longitude: Double, subdivisionIsoCode: String, countryIsoCode: String, green: Int, red: Int, yellow: Int) {
        self.continentCode = continentCode
        
        self.id = id
        
        self.latencyTestUrl = latencyTestUrl
        
        self.latitude = latitude
        
        self.longitude = longitude
        
        self.subdivisionIsoCode = subdivisionIsoCode
        
        self.countryIsoCode = countryIsoCode
        
        self.green = green
        
        self.red = red
        
        self.yellow = yellow
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case continentCode = "continent_code"
        
        case id
        
        case latencyTestUrl = "latency_test_url"
        
        case latitude
        
        case longitude
        
        case subdivisionIsoCode = "subdivision_iso_code"
        
        case countryIsoCode = "country_iso_code"
        
        case green
        
        case red
        
        case yellow
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(continentCode, forKey: .continentCode)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(latencyTestUrl, forKey: .latencyTestUrl)
        
        try container.encode(latitude, forKey: .latitude)
        
        try container.encode(longitude, forKey: .longitude)
        
        try container.encode(subdivisionIsoCode, forKey: .subdivisionIsoCode)
        
        try container.encode(countryIsoCode, forKey: .countryIsoCode)
        
        try container.encode(green, forKey: .green)
        
        try container.encode(red, forKey: .red)
        
        try container.encode(yellow, forKey: .yellow)
    }
}
