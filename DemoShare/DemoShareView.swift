//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        VStack(spacing: 0) {
            TopView(viewModel: viewModel)
            
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
                    if viewModel.channels.count == 0 {
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
        }
        .allowsHitTesting(!viewModel.loading)
    }
}

struct TopView: View {
    
    @ObservedObject var viewModel: DemoShareViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.dismissShareSheet()
            }, label: {
                Text("Cancel")
            })
            Spacer()
            Button(action: {
                Task {
                    do {
                        try await viewModel.sendMessage()
                    } catch {
                        viewModel.dismissShareSheet()
                    }
                }
            }, label: {
                if viewModel.loading {
                    ProgressView()
                } else {
                    Text("Send")
                        .bold()
                }
            })
            .disabled(viewModel.selectedChannel == nil)

        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .overlay(
            Text("Send to")
                .bold()
        )
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
            .cornerRadius(8)
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
                            ChatChannelAvatarView.asView(
                                (channel: channel, currentUserId: viewModel.currentUserId)
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

extension ChatChannel: Identifiable {
    public var id: String {
        return cid.rawValue
    }
}
