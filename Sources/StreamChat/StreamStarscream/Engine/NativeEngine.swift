//
//  NativeEngine.swift
//  Starscream
//
//  Created by Dalton Cherry on 6/15/19.
//  Copyright © 2019 Vluxe. All rights reserved.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class NativeEngine: NSObject, Engine, URLSessionDataDelegate, URLSessionWebSocketDelegate {
    private var task: URLSessionWebSocketTask?
    weak var delegate: EngineDelegate?

    func register(delegate: EngineDelegate) {
        self.delegate = delegate
    }

    func start(request: URLRequest) {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        task = session.webSocketTask(with: request)
        doRead()
        task?.resume()
    }

    func stop(closeCode: UInt16) {
        let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: Int(closeCode)) ?? .normalClosure
        task?.cancel(with: closeCode, reason: nil)
    }

    func forceStop() {
        stop(closeCode: UInt16(URLSessionWebSocketTask.CloseCode.abnormalClosure.rawValue))
    }

    func write(string: String, completion: (() -> ())?) {
        task?.send(.string(string), completionHandler: { (error) in
            completion?()
        })
    }

    func write(data: Data, opcode: FrameOpCode, completion: (() -> ())?) {
        switch opcode {
        case .binaryFrame:
            task?.send(.data(data), completionHandler: { (error) in
                completion?()
            })
        case .textFrame:
            let text = String(data: data, encoding: .utf8)!
            write(string: text, completion: completion)
        case .ping:
            task?.sendPing(pongReceiveHandler: { (error) in
                completion?()
            })
        default:
            break //unsupported
        }
    }

    private func doRead() {
        task?.receive { [weak self] (result) in
            switch result {
            case .success(let message):
                switch message {
                case .string(let string):
                    self?.broadcast(event: .text(string))
                case .data(let data):
                    self?.broadcast(event: .binary(data))
                @unknown default:
                    break
                }
                break
            case .failure(let error):
                self?.broadcast(event: .error(error))
            }
            self?.doRead()
        }
    }

    private func broadcast(event: WebSocketEvent) {
        delegate?.didReceive(event: event)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        let p = `protocol` ?? ""
        broadcast(event: .connected([HTTPWSHeader.protocolName: p]))
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        var r = ""
        if let d = reason {
            r = String(data: d, encoding: .utf8) ?? ""
        }
        broadcast(event: .disconnected(r, UInt16(closeCode.rawValue)))
    }
}
