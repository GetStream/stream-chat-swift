//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

// MARK: - Sample Data

let sampleLogs: [LogEntry] = [
    LogEntry(
        timestamp: Date().addingTimeInterval(-3600),
        level: .error,
        subsystems: [.httpRequests],
        functionName: "performRequest(_:)",
        description: """
        HTTP Request Failed:
        URL: https://api.example.com/users/profile
        Method: GET
        Status Code: 404
        Headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
            "User-Agent": "MyApp/1.0"
        }
        Response Body: {
            "error": {
                "code": "USER_NOT_FOUND",
                "message": "The requested user profile could not be found",
                "details": {
                    "userId": "12345",
                    "timestamp": "2024-03-15T10:30:00Z"
                }
            }
        }
        """
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-1800),
        level: .info,
        subsystems: [.authentication],
        functionName: "loginUser(email:password:)",
        description: "User successfully authenticated with email: user@example.com"
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-900),
        level: .warning,
        subsystems: [.database],
        functionName: "saveContext()",
        description: "Core Data context save took longer than expected: 2.3 seconds. Consider optimizing batch operations."
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-300),
        level: .debug,
        subsystems: [.other],
        functionName: "viewDidLoad()",
        description: "Profile view controller loaded successfully. User preferences: dark mode enabled, notifications allowed."
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-60),
        level: .error,
        subsystems: [.httpRequests, .authentication],
        functionName: "processPayment(_:)",
        description: """
        Payment processing failed with critical error:
        Transaction ID: TXN_789012345
        Amount: $99.99 USD
        Payment Method: **** **** **** 1234
        Error Code: GATEWAY_TIMEOUT
        Gateway Response: {
            "status": "failed",
            "error_code": "TIMEOUT",
            "message": "Payment gateway did not respond within timeout period",
            "retry_after": 300,
            "support_reference": "REF_ABC123XYZ"
        }
        """
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-120),
        level: .info,
        subsystems: [.webSocket, .offlineSupport],
        functionName: "connectWebSocket()",
        description: "WebSocket connection established successfully with offline sync enabled"
    ),
    LogEntry(
        timestamp: Date().addingTimeInterval(-30),
        level: .debug,
        subsystems: [.audioPlayback, .audioRecording],
        functionName: "setupAudioSession()",
        description: "Audio session configured for playback and recording with background support"
    )
]
