//
//  StickerApiClient.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 28/03/22.
//

import Foundation
import Combine

@available(iOS 13.0, *)
public enum StickerApi {
    public static let agent = Agent()
    public static let base = URL(string: "https://messenger.stipop.io/v1/")!
    public static var apiKey = ""
    public static var userId = ""
}

protocol EndPointType {
    // MARK: Variables
    var baseURL: String { get }
    var path: String { get }
    var httpMethod: HTTPMethod { get }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

@available(iOS 13.0, *)
public struct Agent {
    struct Response<T> {
        let value: T
        let response: URLResponse
    }

    func run<T: Decodable>(_ request: URLRequest, _ decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<Response<T>, Error> {
        var updatedReq = request
        updatedReq.addValue(StickerApi.apiKey, forHTTPHeaderField: "apikey")
        return URLSession.shared
            .dataTaskPublisher(for: updatedReq)
            .tryMap { result -> Response<T> in
                let value = try decoder.decode(T.self, from: result.data)
                return Response(value: value, response: result.response)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

@available(iOS 13.0, *)
public class StickerApiClient {
    private static var stickerCalls = Set<AnyCancellable>()

    public static func downloadStickers(packageId: Int,_ completion: @escaping ((ResponseBody<EmptyStipopResponse>) -> Void)) {
        StickerApi.call(type: .downloadStickers(packageId: packageId))
            .sink { _  in } receiveValue: { result in completion(result) }
            .store(in: &stickerCalls)
    }

    public static func mySticker(_ completion: @escaping ((ResponseBody<MyStickerBody>) -> Void)) {
        StickerApi.call(type: .mySticker)
            .sink { _  in } receiveValue: { result in completion(result) }
            .store(in: &stickerCalls)
    }

    public static func stickerInfo(stickerId: String,_ completion: @escaping ((ResponseBody<PackageInfoBody>) -> Void)) {
        StickerApi.call(type: .stickerInfo(id: stickerId))
            .sink { _  in } receiveValue: { result in completion(result) }
            .store(in: &stickerCalls)
    }

    public static func trendingStickers(pageNumber: Int, animated: Bool, _ completion: @escaping ((ResponseBody<MyStickerBody>) -> Void)) {
        StickerApi.call(type: .trendingStickers(pageNumber: pageNumber, animated: animated))
            .sink { _  in } receiveValue: { result in completion(result) }
            .store(in: &stickerCalls)
    }

    public static func stickerSend(stickerId: Int,_ completion: ((ResponseBody<EmptyStipopResponse>) -> Void)?) {
        StickerApi.call(type: .stickerSend(stickerId: stickerId))
            .sink { _  in } receiveValue: { result in completion?(result) }
            .store(in: &stickerCalls)
    }

    public static func recentSticker(_ completion: @escaping ((ResponseBody<RecentStickerBody>) -> Void)) {
        StickerApi.call(type: .recentSticker)
            .sink { _  in } receiveValue: { result in completion(result) }
            .store(in: &stickerCalls)
    }

    public static func hideStickers(packageId: Int, _ completion: ((ResponseBody<EmptyStipopResponse>) -> Void)?) {
        StickerApi.call(type: .hideStickers(packageId: packageId))
            .sink { _  in } receiveValue: { result in completion?(result) }
            .store(in: &stickerCalls)
    }

}
