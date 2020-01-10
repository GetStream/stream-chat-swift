//
//  Presenter+Rx.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

extension Presenter: ReactiveCompatible {}

public extension Reactive  where Base: Presenter {
    
    // MARK: - Requests
    
    /// Prepare a request with pagination when the web socket is connected.
    ///
    /// - Parameter pagination: an initial page size (see `Pagination`).
    /// - Returns: an observable pagination for a request.
    func prepareRequest(startPaginationWith pagination: Pagination = .none) -> Observable<Pagination> {
        let connectionObservable: Observable<Void> = Client.shared.rx.connection
            .do(onNext: { [weak base] connection in
                if !connection.isConnected,
                    let base = base,
                    !base.items.isEmpty,
                    (Client.shared.database == nil || InternetConnection.shared.isAvailable) {
                    base.items = []
                    base.next = base.pageSize
                }
            })
            .filter { $0.isConnected } // Client.shared.database != nil ||
            .void()
        
        return Observable.combineLatest(base.loadPagination.asObserver().startWith(pagination), connectionObservable)
            .map { pagination, _ in pagination }
            .filter { [weak base] in
                if let base = base, base.items.isEmpty, $0 != base.pageSize {
                    DispatchQueue.main.async { base.loadPagination.onNext(base.pageSize) }
                    return false
                }
                
                return true
        }
        .share()
    }
    
    // MARK: - Database
    
    /// Prepare a fetch request from a local database with pagination.
    ///
    /// - Returns: an observable pagination for a fetching data from a local database.
    func prepareDatabaseFetch(startPaginationWith pagination: Pagination = .none) -> Observable<Pagination> {
        guard Client.shared.database != nil else {
            return .empty()
        }
        
        return Observable.combineLatest(base.loadPagination.asObserver().startWith(pagination),
                                        InternetConnection.shared.isAvailableObservable.filter({ !$0 }))
            .map { pagination, _ in pagination }
            .filter { $0 != .none && self.shouldMakeDatabaseFetch(with: $0) }
            .share()
    }
    
    func shouldMakeDatabaseFetch(with pagination: Pagination) -> Bool {
        // Reset fetch, if items empty, but pagination is not for the first page.
        if base.items.isEmpty, pagination != base.pageSize {
            DispatchQueue.main.async { self.base.loadPagination.onNext(self.base.pageSize) }
            return false
        }
        
        // Reset fetch, if items are not empty, but pagination if for the first page.
        if !base.items.isEmpty, pagination == base.pageSize {
            DispatchQueue.main.async { self.base.reload() }
            return false
        }
        
        return true
    }
}
