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
    public enum RequestType: EndPointType {
        case mySticker
        case stickerInfo(id: String)
        case trendingStickers(pageNumber: Int, animated: Bool)
        case downloadStickers(packageId: Int)
        case stickerSend(stickerId: Int)
        case recentSticker
        case hideStickers(packageId: Int)

        // MARK: Vars & Lets
        var baseURL: String {
            return base.absoluteString
        }

        var path: String {
            switch self {
            case .mySticker:
                return "mysticker/\(StickerApi.userId)?userId=\(userId)"
            case .stickerInfo(id: let id):
                return ("package/\(id)?" + "userId=\(userId)")
            case .trendingStickers(pageNumber: let pageNumber, animated: let animated):
                return "package" + "?userId=\(userId)&pageNumber=\(pageNumber)&animated=\(animated ? "Y" : "N")"
            case .downloadStickers(packageId: let packageId):
                return "download/\(packageId)?userId=\(userId)&isPurchase=N"
            case .stickerSend(stickerId: let stickerId):
                return "analytics/send/\(stickerId)?userId=\(userId)"
            case .recentSticker:
                return "package/send/\(userId)"
            case .hideStickers(packageId: let packageId):
                return "mysticker/hide/\(userId)/\(packageId)"
            }
        }

        var httpMethod: HTTPMethod {
            switch self {
            case .mySticker, .stickerInfo, .trendingStickers, .recentSticker:
                return .get
            case .downloadStickers, .stickerSend:
                return .post
            case .hideStickers:
                return .put
            }
        }
    }

    public static func call<T>(type: RequestType) -> AnyPublisher<ResponseBody<T>, Error> {
        let url = type.baseURL + type.path
        var request = (URLRequest(url: URL(string: url)!))
        request.httpMethod = type.httpMethod.rawValue
        return agent.run(request)
            .map(\.value)
            .eraseToAnyPublisher()
    }
}
