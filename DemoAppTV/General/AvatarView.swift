//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct AvatarView: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundStyle(.secondary)
        }
        .frame(width: 80, height: 80)
        .clipShape(.circle)
    }
}
