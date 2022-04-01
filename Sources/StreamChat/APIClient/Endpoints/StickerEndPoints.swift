//
//  StickerEndPoints.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 28/03/22.
//

import Foundation
import Combine

@available(iOS 13.0, *)
extension StickerApi {
    public static func mySticker() -> AnyPublisher<ResponseBody<MyStickerBody>, Error> {
        let url = base.absoluteString + "mysticker/\(StickerApi.userId)?userId=\(userId)"
        var request = (URLRequest(url: URL(string: url)!))
        request.httpMethod = "GET"
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    public static func stickerInfo(id: String) -> AnyPublisher<ResponseBody<PackageInfoBody>, Error> {
        let url = base.absoluteString + "package/\(id)?" + "userId=\(userId)"
        var request = (URLRequest(url: URL(string: url)!))
        request.httpMethod = "GET"
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    public static func trendingStickers(pageNumber: Int) -> AnyPublisher<ResponseBody<MyStickerBody>, Error> {
        let url = base.absoluteString + "package" + "?userId=\(userId)&pageNumber=\(pageNumber)"
        var request = (URLRequest(url: URL(string: url)!))
        request.httpMethod = "GET"
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    public static func downloadStickers(packageId: Int) -> AnyPublisher<ResponseBody<EmptyStipopResponse>, Error> {
        let url = base.absoluteString + "download/\(packageId)?userId=\(userId)&isPurchase=N"
        var request = (URLRequest(url: URL(string: url)!))
        request.httpMethod = "POST"
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    public static func stickerSend(stickerId: Int) -> AnyPublisher<ResponseBody<EmptyStipopResponse>, Error> {
        let url = base.absoluteString + "analytics/send/\(stickerId)?userId=\(userId)"
        var request = (URLRequest(url: URL(string: url)!))
        request.httpMethod = "POST"
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    public static func recentSticker() -> AnyPublisher<ResponseBody<RecentStickerBody>, Error> {
        let url = base.absoluteString + "package/send/\(userId)"
        var request = (URLRequest(url: URL(string: url)!))
        request.httpMethod = "GET"
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    public static func hideStickers(packageId: Int) -> AnyPublisher<ResponseBody<EmptyStipopResponse>, Error> {
        let url = base.absoluteString + "mysticker/hide/\(userId)/\(packageId)"
        var request = (URLRequest(url: URL(string: url)!))
        request.httpMethod = "PUT"
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }
}
