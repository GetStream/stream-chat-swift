//
//  Created by Guy Kahlon.
//
//  Copyright © RxSwiftCommunity/RxStarscream All rights reserved.
//  https://github.com/RxSwiftCommunity/RxStarscream

import Foundation
import RxSwift
import RxCocoa
import Starscream

public enum WebSocketEvent {
    case connected
    case disconnected(Error?)
    case message(String)
    case data(Data)
    case pong
}

public class RxWebSocketDelegateProxy<Client: WebSocketClient>: DelegateProxy<Client, NSObjectProtocol>, DelegateProxyType, WebSocketDelegate, WebSocketPongDelegate { // swiftlint:disable:this line_length
    
    private weak var forwardDelegate: WebSocketDelegate?
    private weak var forwardPongDelegate: WebSocketPongDelegate?
    
    fileprivate let subject = PublishSubject<WebSocketEvent>()
    
    public required init(websocket: Client) {
        super.init(parentObject: websocket, delegateProxy: RxWebSocketDelegateProxy.self)
    }
    
    public static func currentDelegate(for object: Client) -> NSObjectProtocol? {
        return object.delegate as? NSObjectProtocol
    }
    
    public static func setCurrentDelegate(_ delegate: NSObjectProtocol?, to object: Client) {
        object.delegate = delegate as? WebSocketDelegate
        object.pongDelegate = delegate as? WebSocketPongDelegate
    }
    
    public static func registerKnownImplementations() {
        self.register { RxWebSocketDelegateProxy(websocket: $0) }
    }
    
    public func websocketDidConnect(socket: WebSocketClient) {
        subject.onNext(WebSocketEvent.connected)
        forwardDelegate?.websocketDidConnect(socket: socket)
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        subject.onNext(WebSocketEvent.disconnected(error))
        forwardDelegate?.websocketDidDisconnect(socket: socket, error: error)
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        subject.onNext(WebSocketEvent.message(text))
        forwardDelegate?.websocketDidReceiveMessage(socket: socket, text: text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        subject.onNext(WebSocketEvent.data(data))
        forwardDelegate?.websocketDidReceiveData(socket: socket, data: data)
    }
    
    public func websocketDidReceivePong(socket: WebSocketClient, data: Data?) {
        subject.onNext(WebSocketEvent.pong)
        forwardPongDelegate?.websocketDidReceivePong(socket: socket, data: data)
    }
    
    deinit {
        subject.onCompleted()
    }
}

extension Reactive where Base: WebSocketClient {
    
    public var response: Observable<WebSocketEvent> {
        return RxWebSocketDelegateProxy.proxy(for: base).subject
    }
    
    public var text: Observable<String> {
        return self.response
            .filter {
                switch $0 {
                case .message:
                    return true
                default:
                    return false
                }
            }
            .map {
                switch $0 {
                case .message(let message):
                    return message
                default:
                    return String()
                }
        }
    }
    
    public var connected: Observable<Bool> {
        return response
            .filter {
                switch $0 {
                case .connected, .disconnected:
                    return true
                default:
                    return false
                }
            }
            .map {
                switch $0 {
                case .connected:
                    return true
                default:
                    return false
                }
        }
    }
    
    public func write(data: Data) -> Observable<Void> {
        return Observable.create { sub in
            self.base.write(data: data) {
                sub.onNext(())
                sub.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    public func write(ping: Data) -> Observable<Void> {
        return Observable.create { sub in
            self.base.write(ping: ping) {
                sub.onNext(())
                sub.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    public func write(string: String) -> Observable<Void> {
        return Observable.create { sub in
            self.base.write(string: string) {
                sub.onNext(())
                sub.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}
