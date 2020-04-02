//
//  Presenter.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 16/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
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
    public var hasNextPage: Bool { next != pageSize }
    /// Checks if presenter items are empty.
    public var isEmpty: Bool { items.isEmpty }
    /// Observe connection errors as `ViewChanges`.
    private(set) lazy var rxConnectionErrors: Driver<ViewChanges> = rx.setupConnectionErrors()
    
    let loadPagination = PublishSubject<Pagination>()
    
    init(pageSize: Pagination) {
        self.pageSize = pageSize
        self.next = pageSize
    }
}

// MARK: - Extensions

public extension Presenter {
    
    /// Reload items.
    func reload() {
        next = pageSize
        items = []
        load(pagination: pageSize)
    }
    
    /// Load the next page of items.
    func loadNext() {
        if hasNextPage {
            load(pagination: next)
        }
    }
    
    private func load(pagination: Pagination) {
        loadPagination.onNext(pagination)
    }
    
    /// Observe connection errors as `ViewChanges`.
    /// - Parameter onNext: a completion block with `ViewChanges`.
    /// - Returns: a subscription.
    func connectionErrors(_ onNext: @escaping Client.Completion<ViewChanges>) -> Subscription {
        rxConnectionErrors.asObservable().bind(to: onNext)
    }
}
