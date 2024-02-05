//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public extension StreamMockServer {

    func pushNotification(
        senderName: String,
        text: String,
        messageId: String,
        cid: String,
        targetBundleId: String
    ) {
        var json: [String: Any]
        if pushNotificationPayload.isEmpty {
            json = TestData.toJson(.pushNotification)
            var aps = json[APNSKey.aps] as? [String: Any]
            var alert = aps?[APNSKey.alert] as? [String: Any]
            alert?[APNSKey.title] = "New message from \(senderName)"
            alert?[APNSKey.body] = text
            aps?[APNSKey.alert] = alert
            json[APNSKey.aps] = aps

            var stream = json[APNSKey.stream] as? [String: Any]
            stream?[APNSKey.messageId] = messageId
            stream?[APNSKey.cid] = cid
            json[APNSKey.stream] = stream
        } else {
            json = pushNotificationPayload
        }

        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? ""
        let urlString = "\(MockServerConfiguration.httpHost):4567/push/\(udid)/\(targetBundleId)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json.jsonToString().data(using: .utf8)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request).resume()
    }

    func recordVideo(name: String, delete: Bool = false, stop: Bool = false) {
        let json: [String: Any] = ["delete": delete, "stop": stop]
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? ""
        let urlString = "\(MockServerConfiguration.httpHost):4567/record_video/\(udid)/\(name)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = json.jsonToString().data(using: .utf8)
        URLSession.shared.dataTask(with: request).resume()
    }

    func revokeJwt(duration: UInt32 = jwtTimeout) {
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? ""
        let urlString = "\(MockServerConfiguration.httpHost):4567/jwt/revoke/\(udid)?duration=\(duration)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request).resume()
    }

    func breakJwt(duration: UInt32 = jwtTimeout) {
        let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? ""
        let urlString = "\(MockServerConfiguration.httpHost):4567/jwt/break/\(udid)?duration=\(duration)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request).resume()
    }
}
