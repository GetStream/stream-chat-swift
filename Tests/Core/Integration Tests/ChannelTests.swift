//
//  ChannelTests.swift
//  StreamChatCoreTests
//
//  Created by Alexey Bukhtin on 26/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import XCTest
import RxSwift
import RxBlocking
@testable import StreamChatClient
@testable import StreamChatCore

final class ChannelTests: TestCase {
    
    let channel = Channel(type: .messaging, id: "integration")
    
    func testCreateDelete() {
        let randomChannelId = "test_channel_\(Int.random(in: 1000...9999))"
        let channel = Channel(type: .messaging, id: randomChannelId)

        channel.create { result in
            do {
                let channelResponse = try result.get()
                XCTAssertEqual(channelResponse.channel, channel)
                self.deleteChannel(channelResponse.channel)
            } catch {
                XCTFail("\(error)")
            }
        }
    }

    func deleteChannel(_ channel: Channel) {
        channel.delete { result in
            do {
                let deletedChannel = try result.get()
                XCTAssertTrue(deletedChannel.isDeleted)
            } catch {
                XCTFail("\(error)")
            }
        }
    }

    func testQuery() {
        channel.query { result in
            do {
                let response = try result.get()
                XCTAssertEqual(response.channel, self.channel)
            } catch {
                XCTFail("\(error)")
            }
        }
    }
    
    func testSendAndDeleteMessage() {
        let messageText = "test \(Date())"
        let like = ReactionType.regular("like", emoji: "👍")
        let love = ReactionType.regular("love", emoji: "❤️")

        expectRequest("Connected with guest token") { [unowned self] test in
            self.channel.rx.onEvent(eventType: .messageNew)
                .map({ event -> Message? in
                    if case .messageNew(let message, _, _, _) = event {
                        XCTAssertEqual(message.text, messageText)
                        
                        return message
                    }
                    
                    return nil
                })
                .unwrap()
                .flatMapLatest { $0.addReaction(type: like) }
                .map { response -> Message? in
                    if let reactionScores = response.message.reactionScores {
                        XCTAssertEqual(reactionScores.scores, [like: 1])
                        XCTAssertEqual(reactionScores.string, "\(like.emoji)1")
                        return response.message
                    }
                    
                    XCTFail("Failed to add a like reaction")
                    
                    return nil
                })
                .unwrap()
                .flatMapLatest { $0.addReaction(type: love) }
                .map { response -> Message? in
                    if let reactionScores = response.message.reactionScores {
                        XCTAssertEqual(reactionScores.scores, [like: 1, love: 1])
                        XCTAssertEqual(reactionScores.string, "\(like.emoji)\(love.emoji)2")
                        return response.message
                    }
                    
                    XCTFail("Failed to add a love reaction")
                    
                    return nil
                })
                .unwrap()
                .flatMapLatest { $0.addReaction(type: love) }
                .map { response -> Message? in
                    if let reactionScores = response.message.reactionScores {
                        XCTAssertEqual(reactionScores.scores, [like: 1, love: 1])
                        XCTAssertEqual(reactionScores.string, "\(like.emoji)\(love.emoji)2")
                        return response.message
                    }
                    
                    XCTFail("Failed to add a 2nd love reaction")
                    
                    return nil
                })
                .unwrap()
                .flatMapLatest { $0.deleteReaction(type: like) }
                .map { response -> Message? in
                    if let reactionScores = response.message.reactionScores {
                        XCTAssertEqual(reactionScores.scores, [love: 1])
                        XCTAssertEqual(reactionScores.string, "\(love.emoji)1")
                        return response.message
                    }
                    
                    XCTFail("Failed to delete a reaction")
                    
                    return nil
                })
                .unwrap()
                .flatMapLatest { $0.deleteReaction(type: love) }
                .map { response -> Message? in
                    XCTAssertNil(response.message.reactionScores)
                    return response.message
                })
                .unwrap()
                .flatMapLatest { $0.rx.delete() }
                .subscribe(onNext: { response in
                    XCTAssertTrue(response.message.isDeleted)
                    test.fulfill()
                })
                .disposed(by: self.disposeBag)
            
            let message = Message(text: messageText)
            
            self.channel.rx.send(message: message)
                .subscribe(onNext: { response in
                    XCTAssertFalse(response.message.id.isEmpty)
                    XCTAssertEqual(response.message.text, messageText)
                })
                .disposed(by: self.disposeBag)
        }
    }
}
