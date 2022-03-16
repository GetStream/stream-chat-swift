//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter

final class StreamMockServer {
    
    private(set) var server: HttpServer = HttpServer()
    private weak var globalSession: WebSocketSession?
    internal var messageDetails: [Dictionary<MessageDetails, String>] = []
    
    func start(port: UInt16) {
        do {
            try server.start(port)
            print("Server status: \(server.state). Port: \(port)")
        } catch {
            print("Server start error: \(error)")
        }
    }
    
    func stop() {
        server.stop()
    }

    func configure() {
        configureWebsockets()
        configureEventEndpoints()
        configureChannelEndpoints()
        configureReactionEndpoints()
        configureMessagingEndpoints()
    }
    
    func writeText(_ text: String) {
        globalSession?.writeText(text)
    }
    
    private func configureWebsockets() {
        server[MockEndpoints.connect] = websocket(connected: { [weak self] session in
            self?.globalSession = session
            self?.onConnect()
        }, disconnected: { [weak self] _ in
            self?.globalSession = nil
        })
    }
    
    // TODO: CIS-1686
    private func onConnect() {
        writeText(TestData.getMockResponse(fromFile: .wsHealthCheck))
    }
}
