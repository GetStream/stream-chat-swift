//
//  unwrap.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 24/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

extension ObservableType {
    func unwrap<T>() -> Observable<T> where E == T? {
        return filter { $0 != nil }.map { $0! }
    }
}
