//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI

struct DemoShareView: View {
    @StateObject var viewModel: DemoShareViewModel
        
    init(
        userCredentials: UserCredentials,
        extensionContext: NSExtensionContext?
    ) {
        let vm = DemoShareViewModel(
            userCredentials: userCredentials,
            extensionContext: extensionContext
        )
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                if viewModel.images.count == 1 {
                    ImageToShareView(image: viewModel.images[0])
                } else {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(viewModel.images, id: \.self) { image in
                                ImageToShareView(image: image, contentMode: .fill)
                            }
                        }
                    }
                }

                TextField("Write a message...", text: $viewModel.text)
                    .padding(.vertical)

                HStack {
                    if viewModel.channels.isEmpty {
                        ProgressView()
                    } else {
                        Text("Select a channel")
                            .font(.subheadline)
                        Spacer()
                    }
                }

                ShareChannelsView(viewModel: viewModel)
            }
            .padding()
            .navigationTitle("Send to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: viewModel.dismissShareSheet)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.loading {
                        ProgressView()
                    } else {
                        Button("Send") {
                            Task {
                                do {
                                    try await viewModel.sendMessage()
                                } catch {
                                    viewModel.dismissShareSheet()
                                }
                            }
                        }
                        .disabled(viewModel.selectedChannel == nil)
                    }
                }
            }
        }
        .allowsHitTesting(!viewModel.loading)
    }
}

struct ImageToShareView: View {
    private let imageHeight: CGFloat = 180
    
    var image: UIImage
    var contentMode: ContentMode = .fit
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .frame(height: imageHeight)
            .clipShape(.rect(cornerRadius: 8))
    }
}

struct ShareChannelsView: View {
    @ObservedObject var viewModel: DemoShareViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.channels) { channel in
                    Button {
                        viewModel.channelTapped(channel)
                    } label: {
                        HStack {
                            ChatChannelAvatarViewRepresentable(
                                channel: channel,
                                currentUserId: viewModel.currentUserId
                            )
                            .frame(width: 64, height: 64)
                            
                            Text(channel.name ?? channel.id)
                                .bold()
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.selectedChannel == channel {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ChatChannelAvatarViewRepresentable: UIViewRepresentable {
    var channel: ChatChannel
    var currentUserId: UserId?

    func makeUIView(context: Context) -> ChatChannelAvatarView {
        ChatChannelAvatarView()
    }

    func updateUIView(_ uiView: ChatChannelAvatarView, context: Context) {
        uiView.content = (channel: channel, currentUserId: currentUserId)
    }
}
