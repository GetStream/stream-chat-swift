//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

class QueryUpdater<ExtraData: ExtraDataTypes, Query: QueryType>: Worker {
    private let databaseObserver: ListDatabaseObserver<Query.Item>
    private let endpointCreator: (Query.DTO, Query.Item) -> Endpoint<Query.Payload>
    
    // MARK: - Init

    init(
        database: DatabaseContainer,
        webSocketClient: WebSocketClient,
        apiClient: APIClient,
        itemCreator: @escaping (Query.Item.DTO) -> Query.Item,
        queryEndpointCreator: @escaping (Query.DTO, Query.Item) -> Endpoint<Query.Payload>
    ) {
        databaseObserver = .init(
            context: database.backgroundReadOnlyContext,
            fetchRequest: Query.Item.allDTOFetchRequest,
            itemCreator: itemCreator
        )
        
        endpointCreator = queryEndpointCreator
        
        super.init(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
        
        startObserving()
    }
    
    // MARK: - Private
    
    private func startObserving() {
        do {
            databaseObserver.onChange = { [weak self] changes in
                self?.handle(changes.map(\.item))
            }
            
            try databaseObserver.startObserving()
        } catch {
            debugPrint(error)
        }
    }
    
    private func handle(_ changedItems: [Query.Item]) {
        loadQueries { [weak self] queryDTOs in
            for item in changedItems {
                for queryDTO in queryDTOs {
                    let queryID = queryDTO.objectID
                    guard
                        let endpoint = self?.endpointCreator(queryDTO, item)
                    else { continue }
                    
                    self?.apiClient.request(endpoint: endpoint) { result in
                        switch result {
                        case let .success(payload):
                            self?.database.write({
                                let session = $0 as! NSManagedObjectContext
                                guard
                                    let queryDTO = session.object(with: queryID) as? Query.DTO,
                                    let itemDTO = session.first(item.dtoFetchRequest)
                                else { return }
                                
                                if payload.items.isEmpty {
                                    // If response doesn't contain item matching the query, unlink it from query
                                    queryDTO.items.remove(itemDTO)
                                } else {
                                    // If response contains item matching the query, link it to the query
                                    queryDTO.items.insert(itemDTO)
                                }
                            }, completion: {
                                if let error = $0 {
                                    debugPrint(error)
                                }
                            })
                        case let .failure(error):
                            debugPrint(error)
                        }
                    }
                }
            }
        }
    }
    
    private func loadQueries(completion: @escaping ([Query.DTO]) -> Void) {
        let context = database.backgroundReadOnlyContext
        context.perform {
            do {
                let request = NSFetchRequest<Query.DTO>(entityName: Query.DTO.entityName)
                let queryDTOs = try context.fetch(request)
                completion(queryDTOs)
            } catch {
                debugPrint(error)
            }
        }
    }
}

extension NSManagedObjectContext {
    func first<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> T? {
        try? fetch(request).first
    }
}
