//
//  StickerApiClient.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 28/03/22.
//

import Foundation
import Combine

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
public enum StickerApi {
    public static let agent = Agent()
    public static let base = URL(string: "https://messenger.stipop.io/v1/")!
    public static var apiKey = ""
    public static var userId = ""
}
