//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct ChannelHeaderView: View {
    let name: String
    let avatarURL: URL?
    let memberCount: Int

    var body: some View {
        HStack(spacing: 24) {
            AvatarView(url: avatarURL)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text("^[\(memberCount) member](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
