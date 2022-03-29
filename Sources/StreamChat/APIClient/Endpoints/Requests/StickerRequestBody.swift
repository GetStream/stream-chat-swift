//
//  StickerRequestBody.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 28/03/22.
//

import Foundation

public struct PackageList: Codable {
    public let packageID: Int?
    public let packageImg: String?
    public let packageName, packageCategory, isWish: String?
    public let order: Int?
    public let language, isNew, isDownload, isView: String?
    public let packageKeywords, packageAnimated, artistName: String?

    enum CodingKeys: String, CodingKey {
        case packageID = "packageId"
        case packageImg, packageName, packageCategory, isWish, order, language, isNew, isDownload, isView, packageKeywords, packageAnimated, artistName
    }
}

// MARK: - Package
public struct Package: Codable {
    public let packageID: Int?
    public let stickers: [Sticker]?
    public let packageImg: String?
    public let packageName, packageCategory: String?
    public let language: String?
    public let isDownload, packageKeywords: String?
    public let artistName: String?

    enum CodingKeys: String, CodingKey {
        case packageID = "packageId"
        case stickers, packageImg, packageName, packageCategory, language, isDownload, packageKeywords, artistName
    }
}


// MARK: - Sticker
public struct Sticker: Codable {
    public let stickerID: Int?
    public let stickerImg: String?
    public let packageID: Int?

    enum CodingKeys: String, CodingKey {
        case stickerID = "stickerId"
        case stickerImg
        case packageID = "packageId"
    }
}


// MARK: - Welcome
public struct ResponseBody<T: Codable>: Codable {
    public let body: T?
    public let header: Header?
}

// MARK: - MyStickerBody
public struct MyStickerBody: Codable {
    public let pageMap: [String: Int]?
    public let packageList: [PackageList]?
}

// MARK: - PackageInfoBody
public struct PackageInfoBody: Codable {
    public let package: Package?
}

// MARK: EmptyResponse
public struct EmptyStipopResponse: Codable { }

// MARK: - Header
public struct Header: Codable {
    public let status, message, code: String?
}
