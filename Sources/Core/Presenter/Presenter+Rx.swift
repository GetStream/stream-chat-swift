//
//  Presenter+Rx.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift
import RxCocoa

extension Presenter: ReactiveCompatible {
    fileprivate static var rxConnectionErrorsKey: UInt8 = 0
}

extension Reactive  where Base: Presenter {
    
    /// Observe connection errors as `ViewChanges`.
    public var connectionErrors: Driver<ViewChanges> {
        associated(to: base, key: &Presenter.rxConnectionErrorsKey) {
            Client.shared.rx.connectionState
                .compactMap({ connection -> ViewChanges? in
                    if case .disconnected(let error) = connection, let disconnectError = error {
                        return .error(disconnectError)
                    }
                    
                    if case .notConnected = connection {
                        return .disconnected
                    }
                    
                    return nil
                })
                .asDriver(onErrorJustReturn: .none)
        }
    }
}

public extension Reactive  where Base: Presenter {
    
    // MARK: Requests
    
    /// Prepare a request with pagination when the web socket is connected.
    ///
    /// - Parameter pagination: an initial page size (see `Pagination`).
    /// - Returns: an observable pagination for a request.
    func prepareRequest(startPaginationWith pagination: Pagination = []) -> Observable<Pagination> {
        let connectionObservable = Client.shared.rx.connectionState
            .do(onNext: { [weak base] connection in
                if !connection.isConnected,
                    let base = base,
                    !base.items.isEmpty,
                    (Client.shared.database == nil || InternetConnection.shared.isAvailable) {
                    base.items = []
                    base.next = base.pageSize
                }
            })
            .filter { $0.isConnected }
        
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
    func prepareDatabaseFetch(startPaginationWith pagination: Pagination = []) -> Observable<Pagination> {
        guard Client.shared.database != nil else {
            return .empty()
        }
        
        return Observable.combineLatest(base.loadPagination.asObserver().startWith(pagination),
                                        InternetConnection.shared.rx.state.filter({ $0 != .available }))
            .map { pagination, _ in pagination }
            .filter { [weak base] in !$0.isEmpty && (base?.rx.shouldMakeDatabaseFetch(with: $0) ?? false) }
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
