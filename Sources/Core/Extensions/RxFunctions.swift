//
//  RxFunctions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 24/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift
import RxCocoa

public extension ObservableType {
    /// Map an event value to `Void()`.
    func void() -> Observable<Void> {
        map { _ in Void() }
    }
}

public extension ObservableType where Element == ViewChanges {
    
    func asClientDriver() -> Driver<Element> {
        asDriver(onErrorRecover: { error in
            if let clientError = error as? ClientError {
                return Driver.just(Element.error(clientError))
            }
            
            return Driver.just(Element.error(.unexpectedError(description: error.localizedDescription, error: error)))
        })
    }
}
