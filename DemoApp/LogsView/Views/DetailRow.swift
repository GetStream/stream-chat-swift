//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title + ":")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}
