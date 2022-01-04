//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct ImageView: View {
    init(
        url: URL?
    ) {
        url.map(image.load)
    }

    @ObservedObject private var image = FetchImage()
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray)
            image.view?
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
                .mask(Circle())
        }
    }
}
