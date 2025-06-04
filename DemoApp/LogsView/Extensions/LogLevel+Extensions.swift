//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

extension LogLevel {
    var displayName: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        }
    }

    var color: Color {
        switch self {
        case .debug:
            return .purple
        case .info:
            return .blue
        case .warning:
            return .yellow
        case .error:
            return .red
        }
    }

    var icon: String {
        switch self {
        case .debug:
            return "ant.circle"
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .error:
            return "xmark.circle"
        }
    }
}
