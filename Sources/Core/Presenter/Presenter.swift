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

/// A presenter.
public class Presenter<T> {
    
    /// A list of presenter items.
    public internal(set) var items = [T]()
    var pageSize: Pagination
    var next: Pagination
    /// Checks if presenter items are empty.
    public var isEmpty: Bool { return items.isEmpty }
    let loadPagination = PublishSubject<Pagination>()
    
    init(pageSize: Pagination) {
        self.pageSize = pageSize
        self.next = pageSize
    }
    
    func request(startPaginationWith pagination: Pagination = .none) -> Observable<Pagination> {
        let connectionObservable = Client.shared.connection.connected({ [weak self] isConnected in
            if !isConnected, let self = self, !self.items.isEmpty {
                self.items = []
                self.next = self.pageSize
            }
        })
        
        return Observable.combineLatest(loadPagination.asObserver().startWith(pagination), connectionObservable)
            .map { pagination, _ in pagination }
            .filter { [weak self] in
                if let self = self, self.items.isEmpty, $0 != self.pageSize {
                    DispatchQueue.main.async { self.loadPagination.onNext(self.pageSize) }
                    return false
                }
                
                return true
            }
            .share()
    }
    
    /// Reload items.
    public func reload() {
        next = pageSize
        items = []
        load(pagination: pageSize)
    }
    
    /// Load the next page of items.
    public func loadNext() {
        if next != pageSize {
            load(pagination: next)
        }
    }
    
    private func load(pagination: Pagination) {
        loadPagination.onNext(pagination)
    }
}
