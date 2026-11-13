//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/query-channels/

import Foundation
import StreamChat

struct Snippets_03_02_QueryChannels {
    var chatClient: ChatClient!
    var userId: UserId!
    var cids: [ChannelId]!
    var channelId: ChannelId!
    var thirtyDaysAgo: Date!

    func queryingChannels() {
        let controller = chatClient.channelListController(
          query: .init(
            filter: .and([.equal(.type, to: .messaging), .containMembers(userIds: ["thierry"])]),
            sort: [.init(key: .lastMessageAt, isAscending: false)],
            pageSize: 10
          )
        )

        controller.synchronize { error in
          if let error = error {
            // handle error
            print(error)
          } else {
            // access channels
            print(controller.channels)

            // load more if needed
            controller.loadNextChannels(limit: 10) { error in
              // handle error / access channels
            }
          }
        }
    }

    func messagingAndTeamChannels() {
        let currentUserChannels = chatClient.channelListController(
          query: .init(
            filter: .and([
              .equal(.type, to: .messaging),
              .containMembers(userIds: [chatClient.currentUserId!])
            ])
          )
        )

        currentUserChannels.synchronize()
    }

    func listingAUsersChannels() {
        let filter: Filter<ChannelListFilterScope> = .and([
          .equal(.type, to: .messaging),
          .containMembers(userIds: [userId]),
          .or([.equal(.hidden, to: true), .equal(.hidden, to: false)])
        ])
        suppressUnusedWarning(filter)
    }

    func filteringByMemberData() {
        let filter: Filter<ChannelListFilterScope> = .and([
          .in(.cid, values: cids),
          .containMembers(userIds: [userId]),
          .or([.equal(.hidden, to: true), .equal(.hidden, to: false)])
        ])
        suppressUnusedWarning(filter)
    }

    func filteringByMemberData2() {
        let filter: Filter<ChannelListFilterScope> = .and([
          .containMembers(userIds: [userId]),
          .or([.in(.cid, values: cids), .equal(.muted, to: true)]),
          .or([.equal(.hidden, to: true), .equal(.hidden, to: false)])
        ])
        suppressUnusedWarning(filter)
    }

    func activeMemberCount() {
        var query = ChannelListQuery(
          filter: .and([.equal(.type, to: .messaging), .containMembers(userIds: ["thierry"])]),
          pageSize: 10
        )
        query.includeActiveMemberCount = true

        let controller = chatClient.channelListController(query: query)
        controller.synchronize { error in
          guard error == nil, let channel = controller.channels.first else { return }
          // activeMemberCount is nil when the count could not be computed
          let memberTotal = channel.activeMemberCount ?? channel.memberCount
          print(memberTotal)
        }
    }

    func pagination() {
        let controller = chatClient.channelListController(
          query: .init(
            filter: .containMembers(userIds: ["thierry"]),
            pageSize: 10
          )
        )

        // Get the first 10 channels
        controller.synchronize { error in
          if let error = error {
            // handle error
            print(error)
          } else {
            // Access channels
            print(controller.channels)

            // Get the next 10 channels
            controller.loadNextChannels { error in
              // handle error / access channels
              print(error ?? controller.channels)
            }
          }
        }
    }

    func channelCreationAndWatching() async throws {
        let channelId = ChannelId(type: .messaging, id: "general")

        // Controller: synchronize creates the channel if needed and starts watching it
        let channelController = try chatClient.channelController(createChannelWithId: channelId)
        channelController.synchronize()

        // State layer: get(watch:) creates the channel if needed and, with watch: true, watches it
        let chat = try chatClient.makeChat(with: channelId)
        try await chat.get(watch: true)
    }

    func filterBestPractices() {
        // Most performant: Filter by CID
        let cidFilter: Filter<ChannelListFilterScope> = .equal(.cid, to: channelId)

        // Recommended for social messaging
        let membersFilter: Filter<ChannelListFilterScope> = .and([
          .equal(.type, to: .messaging),
          .containMembers(userIds: [userId])
        ])

        // Not recommended: type alone
        let typeFilter: Filter<ChannelListFilterScope> = .equal(.type, to: .messaging)
        suppressUnusedWarning(cidFilter, membersFilter, typeFilter)
    }

    func sortBestPractices() {
        let sort: [Sorting<ChannelListSortingKey>] = [.init(key: .lastMessageAt, isAscending: false)]
        suppressUnusedWarning(sort)
    }

    func goodPatternSelectiveFilterWithIndexedFields() {
        // GOOD: Selective filter using indexed fields
        let controller = chatClient.channelListController(
          query: .init(
            filter: .and([
              .equal(.type, to: .messaging),
              .containMembers(userIds: [userId]),
              .greaterOrEqual(.lastMessageAt, than: thirtyDaysAgo)
            ]),
            sort: [.init(key: .lastMessageAt, isAscending: false)],
            pageSize: 20
          )
        )

        controller.synchronize()
    }

    func badPatternOverlyBroadOrComplexFilters() {
        // BAD: Type-only filter (too broad)
        let broadFilter: Filter<ChannelListFilterScope> = .equal(.type, to: .messaging)

        // BAD: Deep nesting of logical operators
        let nestedFilter: Filter<ChannelListFilterScope> = .and([
          .or([.equal(.frozen, to: true), .equal(.disabled, to: true)]),
          .or([.equal(.hidden, to: true), .equal(.muted, to: true)])
        ])
        suppressUnusedWarning(broadFilter, nestedFilter)
    }

    func usingPredefinedFiltersInProduction() {
        // The filter and sort templates are configured server-side in the Dashboard.
        let controller = chatClient.channelListController(
          query: .init(
            predefinedFilter: "user_messaging_channels",
            filterValues: ["user_id": .string(userId)]
          )
        )

        controller.synchronize()
    }

    func usingPredefinedFilters() {
        let controller = chatClient.channelListController(
          query: .init(
            predefinedFilter: "user_messaging_channels",
            filterValues: ["user_id": .string("user123")]
          )
        )

        controller.synchronize()
    }

    func queryComplexity() {
        // RECOMMENDED: Simple, selective filter with indexed fields
        let filter: Filter<ChannelListFilterScope> = .and([
          .equal(.type, to: .messaging),
          .containMembers(userIds: [userId]),
          .greaterOrEqual(.lastMessageAt, than: thirtyDaysAgo)
        ])
        suppressUnusedWarning(filter)
    }

    func paginationBestPractices() {
        // Efficient pagination with members filter
        let controller = chatClient.channelListController(
          query: .init(
            filter: .and([.equal(.type, to: .messaging), .containMembers(userIds: [userId])]),
            sort: [.init(key: .lastMessageAt, isAscending: false)],
            pageSize: 20
          )
        )

        controller.synchronize { error in
          guard error == nil else { return }
          // Load the next page with the same filter and sort
          controller.loadNextChannels(limit: 20) { error in
            // handle error / access channels
          }
        }
    }
}
