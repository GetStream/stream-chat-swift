//
//  RxGesture+Extensions.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 15/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import RxGesture

typealias GestureFactory = (AnyFactory, when: GestureRecognizerState)

extension TapControlEvent {
    static var `default`: GestureFactory {
        return (.tap(configuration: { $1.simultaneousRecognitionPolicy = .never }), when: .recognized)
    }
}

extension LongPressControlEvent {
    static var `default`: GestureFactory {
        return (.longPress(configuration: { gesture, delegate in
            gesture.minimumPressDuration = 0.3
            delegate.simultaneousRecognitionPolicy = .never
        }), when: .began)
    }
}

extension Reactive where Base: View {
    
    /// Reactive wrapper for multiple view gesture recognizers.
    /// It automatically attaches the gesture recognizers to the receiver view.
    /// The value the `Observable` emits is the gesture recognizer itself.
    ///
    /// rx.anyGesture can't error and is subscribed/observed on main scheduler.
    /// - parameter factories: a `(Factory + state)` collection you want to use to create the `GestureRecognizers` to add and observe
    /// - returns: a `ControlEvent<G>` that re-emit the gesture recognizer itself
    func anyGesture(_ factories: [GestureFactory]) -> ControlEvent<GestureRecognizer> {
        let observables = factories.map { [weak base] gesture, state -> Observable<GestureRecognizer> in
            base?.rx.gesture(gesture).when(state).asObservable() ?? .empty()
        }
        
        return ControlEvent(events: Observable.from(observables).merge())
    }
}
