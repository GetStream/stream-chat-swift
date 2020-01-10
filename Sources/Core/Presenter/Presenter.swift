//
//  Presenter.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 16/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// A general presenter for making requests with pagination.
public class Presenter {
    
    /// A list of presenter items.
    public internal(set) var items = [PresenterItem]()
    /// A pagination of an initial page size, e.g. `.limit(25)`
    public internal(set) var pageSize: Pagination
    /// A pagination for the next request.
    public internal(set) var next: Pagination
    /// Checks if the presenter can load more items.
    public var hasNextPage: Bool { return next != pageSize }
    /// Checks if presenter items are empty.
    public var isEmpty: Bool { return items.isEmpty }
    
    let loadPagination = PublishSubject<Pagination>()
    
    private(set) lazy var connectionErrors: Driver<ViewChanges> = Client.shared.rx.connection
        .map { connection -> ViewChanges? in
            if case .disconnected(let error) = connection, let webSocketError = error as? ClientErrorResponse {
                return .error(AnyError(error: webSocketError))
            }
            
            if case .notConnected = connection {
                return .disconnected
            }
            
            return nil
        }
        .unwrap()
        .asDriver(onErrorJustReturn: .none)
    
    init(pageSize: Pagination) {
        self.pageSize = pageSize
        self.next = pageSize
    }
    
    /// Reload items.
    public func reload() {
        next = pageSize
        items = []
        load(pagination: pageSize)
    }
    
    /// Load the next page of items.
    public func loadNext() {
        if hasNextPage {
            load(pagination: next)
        }
    }
    
    private func load(pagination: Pagination) {
        loadPagination.onNext(pagination)
    }
}
