//
//  StickerResponseBody.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 28/03/22.
//

import Foundation

// MARK: - ResponseBody
public struct ResponseBody<T: Codable>: Codable {
    public let body: T?
    public let header: Header?
}

// MARK: - PackageList
public struct PackageList: Codable, Hashable {
    public let packageID: Int?
    public let packageImg: String?
    public let packageName, packageCategory, price, isWish: String?
    public let order: Int?
    public let language, isNew, isDownload, isView: String?
    public let packageKeywords, packageAnimated, artistName: String?
    enum CodingKeys: String, CodingKey {
        case packageID = "packageId"
        case packageImg, packageName, packageCategory, isWish, order, language, isNew, isDownload, isView, packageKeywords, packageAnimated, artistName, price
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

// MARK: - MyStickerBody
public struct MyStickerBody: Codable {
    public let pageMap: [String: Int]?
    public let packageList: [PackageList]?
}

// MARK: - PackageInfoBody
public struct PackageInfoBody: Codable {
    public let package: Package?
}

public struct RecentStickerBody: Codable {
    public let stickerList: [Sticker]?
    public let pageMap: [String: Int]?
}

// MARK: EmptyResponse
public struct EmptyStipopResponse: Codable { }

// MARK: - Header
public struct Header: Codable {
    public let status, message, code: String?
}

// MARK: StickerMENU
public class StickerMenu: Codable, Equatable {
    public static func == (lhs: StickerMenu, rhs: StickerMenu) -> Bool {
        lhs.menuId == rhs.menuId
    }
    public let image: String?
    public let menuId: Int?
    public let name: String?

    public init(image: String, menuId: Int, name: String) {
        self.image = image
        self.menuId = menuId
        self.name = name
    }

    public static func getDefaultSticker() -> [StickerMenu] {
        var menu = [StickerMenu]()
        menu.append(.init(image: "https://img.stipop.io/2020/11/23/1606123362817_IE7darbhoR.gif", menuId: 5682, name: "Cute Baby Axolotl"))
        menu.append(.init(image: "https://img.stipop.io/2021/7/7/1625615224234_gn8QGj9ryD.gif", menuId: 7227, name: "Cute duck Duggy"))
        menu.append(.init(image: "https://img.stipop.io/2020/12/18/1608261102770_6T1UkUst0l.gif", menuId: 5851, name: "Tubby Nugget Winter Pack"))
        menu.append(.init(image: "https://img.stipop.io/2021/2/10/1612910010258_LqupKfShY4.gif", menuId: 6223, name: "Mushroom Movie"))
        menu.append(.init(image: "https://img.stipop.io/2021/4/17/1618634173644_BC21rzJCti.gif", menuId: 6713, name: "Snowoo2"))
        menu.append(.init(image: "https://img.stipop.io/2020/9/8/1599612864041_AQn6C2GpVn.gif", menuId: 5272, name: "Jolly John Season 1"))
        return menu
    }

    public static func getDefaultStickerIds() -> [Int] {
        getDefaultSticker().compactMap { $0.menuId }
    }
}
