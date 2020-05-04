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
    
    /// NOTE
    /// Under the hood, `Pagination` is a Set, and Sets are unordered. This causes encodings to have nondeterministic string outputs.
    /// For example, `complexPagination` can be encoded in any combination of its `PaginationOption`s. So both:
    /// `{"id_gt":"42","id_lt":"92","offset":10,"limit":10}`
    /// and
    /// `{"id_lt":"92","id_gt":"42","offset":10,"limit":10}`
    /// are valid, although our tests will fail for the latter.
    /// If we assume the ordering is purely random, we have 1/4! chance of getting the ordering we are searching for.
    /// For 1 roll, this means 1/24 = 0,041
    /// For n rolls, our chances of getting the ordering we want _at least once_ is 1-(23/24)^n
    /// So for 100 rolls, our chance of getting it once is 1-(23/24)^100 = 0,985
    /// That's why we encode and compare the strings (up to) 100 times, to have a confidence interval of %98,5.
    /// See `func nonDeterministicAssertEqual`
    
    func testChannelQueryEncoding() {
        let query = { ChannelQuery(channel: self.channel,
                                   messagesPagination: self.simplePagination(),
                                   membersPagination: self.mediumPagination(),
                                   watchersPagination: self.complexPagination(),
                                   options: .watch) }
        
        let expectedString = #"{"messages":{"limit":10},"watch":true,"watchers":{"id_gt":"42","id_lt":"92","offset":10,"limit":10},"members":{"limit":10,"offset":20}}"#
        
        nonDeterministicAssertEqual(expectedString, try encode(query()))
    }
    
    func testChannelsQueryEncoding() {
        let query = { ChannelsQuery(filter: self.simpleFilter,
                                    sort: [.init("name", isAscending: true)],
                                    pagination: self.complexPagination(),
                                    messagesLimit: self.mediumPagination(),
                                    options: .presence) }
        
        let expectedString = #"{"offset":10,"sort":[{"field":"name","direction":1}],"filter_conditions":{"id":42},"message_limit":10,"presence":true,"limit":10,"id_lt":"92","id_gt":"42"}"#
        
        nonDeterministicAssertEqual(expectedString, try encode(query()))
    }
    
    func testSearchQueryEncoding() {
        let query = { SearchQuery(filter: self.mediumFilter,
                                  query: "hello",
                                  pagination: self.mediumPagination()) }
        
        let expectedString = #"{"limit":10,"query":"hello","offset":20,"filter_conditions":{"$and":[{"members":{"$in":["john"]}},{"id":{"$autocomplete":"ro"}}]}}"#
        
        nonDeterministicAssertEqual(expectedString, try encode(query()))
    }
    
    func testUsersQueryEncoding() {
        let query = { UsersQuery(filter: self.complexFilter,
                               sort: .init("name", isAscending: true),
                               options: .all) }
        
        let expectedString = #"{"presence":true,"state":true,"watch":true,"sort":{"field":"name","direction":1},"filter_conditions":{"$and":[{"members":{"$in":["john"]}},{"unread_count":0},{"$or":[{"id":{"$gt":42}},{"$and":[{"avatar":{"$ne":"null"}},{"name":{"$autocomplete":"ro"}}]}]}]}}"#
        
        nonDeterministicAssertEqual(expectedString, try encode(query()))
    }
    
    private func error(with message: String) -> NSError {
        NSError(domain: "QueryGenerationTests", code: -1, userInfo: ["message:": message])
    }
    
    /// - Returns: the string representation of the data
    /// - Throws: Error to fail the test
    private func encode<T: Encodable>(_ data: T) throws -> String {
        do {
            let encoded = try encoder.encode(data)
            guard let stringRep = String(data: encoded, encoding: .utf8) else {
                throw error(with: "Failed to get string representation for data")
            }
            return stringRep
        } catch let err {
            throw error(with: "Error during encoding: \(err)")
        }
    }
    
    private func nonDeterministicAssertEqual<T>(_ expression1: @autoclosure () throws -> T,
                                                _ expression2: @autoclosure () throws -> T,
                                                tryUpTo times: Int = 100) where T : StringProtocol {
        var equal = false
        
        do {
            let expr1 = try expression1()
            let expr2 = try expression2()
            
            guard expr1.count == expr2.count else {
                throw error(with: "Representation lenghts don't match")
            }
            
            equal = equal || (expr1 == expr2)
            
            for _ in 0..<(times - 1) {
                if equal { break }
                try equal = equal || (expression1() == expression2())
            }
        } catch {
            XCTFail("Threw \(error)")
            return
        }
        
        XCTAssert(equal, "Encoding did not match expected")
    }
}
