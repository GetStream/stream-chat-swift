//
//  QueryEncodingTests.swift
//  StreamChatClient
//
//  Created by Bahadir Oncel on 10.04.2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import XCTest
@testable import StreamChatClient

final class QueryEncodingTests: XCTestCase {
    private let channel = Client(config: .init(apiKey: "test")).channel(type: .messaging, id: "general")
    private let encoder = JSONEncoder()
    
    private let simpleFilter: Filter = .equal("id", to: 42)
    private let mediumFilter: Filter = .in("members", ["john"]) & .autocomplete("id", with: "ro")
    private let complexFilter: Filter = .in("members", ["john"])
        & .equal("unread_count", to: 0)
        & (.greater("id", than: 42) | (.notEqual("avatar", to: "null") & .autocomplete("name", with: "ro")))
    
    private let simplePagination: () -> Pagination = { [.limit(10)] }
    private let mediumPagination: () -> Pagination = { [.limit(10), .offset(20)] }
    private let complexPagination: () -> Pagination = { [.limit(10), .offset(10), .greaterThan("42"), .lessThan("92")] }
    
    func testChannelQueryEncoding() {
        let query = { ChannelQuery(channel: self.channel,
                                   messagesPagination: self.simplePagination(),
                                   membersPagination: self.mediumPagination(),
                                   watchersPagination: self.complexPagination(),
                                   options: .watch) }
        
        let expectedString = #"{"messages":{"limit":10},"watch":true,"watchers":{"id_gt":"42","id_lt":"92","offset":10,"limit":10},"members":{"limit":10,"offset":20}}"#
        
        AssertJSONEqual(Data(expectedString.utf8), try encode(query()))
    }
    
    func testChannelsQueryEncoding() {
        let query = { ChannelsQuery(filter: self.simpleFilter,
                                    sort: [.init("name", isAscending: true)],
                                    pagination: self.complexPagination(),
                                    messagesLimit: self.mediumPagination(),
                                    options: .presence) }

        let expectedString = #"{"offset":10,"sort":[{"field":"name","direction":1}],"filter_conditions":{"id":42},"message_limit":10,"presence":true,"limit":10,"id_lt":"92","id_gt":"42"}"#

        AssertJSONEqual(Data(expectedString.utf8), try encode(query()))
    }

    func testSearchQueryEncoding() {
        let query = { SearchQuery(filter: self.mediumFilter,
                                  query: "hello",
                                  pagination: self.mediumPagination()) }

        let expectedString = #"{"limit":10,"query":"hello","offset":20,"filter_conditions":{"$and":[{"members":{"$in":["john"]}},{"id":{"$autocomplete":"ro"}}]}}"#

        AssertJSONEqual(Data(expectedString.utf8), try encode(query()))
    }

    func testUsersQueryEncoding() {
        let query = { UsersQuery(filter: self.complexFilter,
                               sort: .init("name", isAscending: true),
                               pagination: self.mediumPagination(),
                               options: .all) }

        let expectedString = #"{"filter_conditions":{"$and":[{"members":{"$in":["john"]}},{"unread_count":0},{"$or":[{"id":{"$gt":42}},{"$and":[{"avatar":{"$ne":"null"}},{"name":{"$autocomplete":"ro"}}]}]}]},"presence":true,"state":true,"offset":20,"watch":true,"limit":10}"#

        AssertJSONEqual(Data(expectedString.utf8), try encode(query()))
    }
    
    /// - Returns: Encoded data
    /// - Throws: Error to fail the test
    private func encode<T: Encodable>(_ data: T) throws -> Data {
        do {
            let encoded = try encoder.encode(data)
            return encoded
        } catch let err {
            throw error(domain: "QueryEncodingTests", message: "Error during encoding: \(err)")
        }
    }
}
