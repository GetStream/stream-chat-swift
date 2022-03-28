//
//  RemoteImageView.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 28/03/22.
//

import SwiftUI
import Nuke

@available(iOS 14.0.0, *)
struct RemoteImageView: View {
    var url: URL
    var transition: AnyTransition = .opacity
    @State private var uiImage: UIImage?

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color(white: 0.9))
            uiImage.map { uiImage in
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .transition(transition)
            }
        }
        .onAppear {
            ImagePipeline.shared.loadImage(with: self.url) { result in
                switch result {
                case .success(let response): self.uiImage = response.image
                case .failure(let error): print(error)
                }
            }
        }
    }
}
