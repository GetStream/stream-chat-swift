//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class SyncRepository {
    /// Do not call the sync endpoint more than once every six seconds
    let syncCooldown: TimeInterval = 6.0
    let database: DatabaseContainer
    let client: ChatClient

    init(client: ChatClient, database: DatabaseContainer) {
        self.client = client
        self.database = database
    }

    func syncChannels(completion: @escaping () -> Void) {
        guard client.config.isLocalStorageEnabled else {
            completion()
            return
        }

        obtainLastSyncDate { lastSyncAt in
            guard let lastSyncAt = lastSyncAt, self.shouldSyncWithAPI(since: lastSyncAt) else {
                completion()
                return
            }

            let cids = self.getExistingChannelIds()
            let endpoint: Endpoint<MissingEventsPayload> = .missingEvents(since: lastSyncAt, cids: cids)

            self.client.apiClient.request(endpoint: endpoint) {
                switch $0 {
                case let .success(payload):
                    self.client.eventNotificationCenter.process(
                        payload.eventPayloads.asEvents(),
                        postNotifications: false
                    ) {
                        self.bumpLastSyncDate(lastReceivedEventDate: payload.eventPayloads.first?.createdAt ?? lastSyncAt) {
                            completion()
                        }
                    }
                case let .failure(error):
                    log.error("Failed cleaning up channels data: \(error).")
                    completion()
                }
            }
        }
    }

    private func obtainLastSyncDate(completion: @escaping (Date?) -> Void) {
        var lastReceivedEventDate: Date?
        database.viewContext.performAndWait {
            lastReceivedEventDate = self.database.viewContext.currentUser?.lastReceivedEventDate
        }
        completion(lastReceivedEventDate)
    }

    private func bumpLastSyncDate(lastReceivedEventDate: Date, completion: @escaping () -> Void) {
        database.write { session in
            session.currentUser?.lastReceivedEventDate = lastReceivedEventDate
        } completion: { error in
            if let error = error {
                log.error(error)
            }
            completion()
        }
    }

    private func shouldSyncWithAPI(since: Date, now: Date = .init()) -> Bool {
        now.timeIntervalSince(since) > syncCooldown
    }

    private func getExistingChannelIds() -> [ChannelId] {
        let request = ChannelDTO.allChannelsFetchRequest
        request.fetchLimit = 1000
        request.propertiesToFetch = ["cid"]

        let results = (try? database.viewContext.fetch(request)) ?? []
        let cids = results.compactMap { try? ChannelId(cid: $0.cid) }
        return cids
    }
}
