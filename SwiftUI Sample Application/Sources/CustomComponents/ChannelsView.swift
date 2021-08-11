//
// Created by kojiba on 10.08.2021.
//

import SwiftUI
import StreamChat

struct ChannelListView: View {
    @ObservedObject var channelList: ChatChannelListController.ObservableObject

    init(channelListController: ChatChannelListController) {
        self.channelList = channelListController.observableObject
    }

    var body: some View {
        stateView()
            .onAppear {
                channelList.controller.synchronize()
            }
    }

    var channelsListView: some View {
        VStack {
            List(channelList.channels, id: \.self) { channel in
                Text(channel.name ?? "missing channel name")
            }
        }
    }

    var loadingView: some View {
        VStack {
            HStack {
                Text("Loading...")
            }
        }
    }

    var errorView: some View {
        VStack {
            HStack {
                Text("Error :(")
            }
        }
    }

    func stateView() -> AnyView {
        switch channelList.state {
        case .initialized:
            print(#function, "initialized")
            return loadingView.toAnyView()

        case .localDataFetched:
            print(#function, "localDataFetched")
            return loadingView.toAnyView()

        case .localDataFetchFailed(_):
            print(#function, "localDataFetchFailed")
            return errorView.toAnyView()

        case .remoteDataFetched:
            print(#function, "remoteDataFetched")
            return channelsListView.toAnyView()

        case .remoteDataFetchFailed(_):
            print(#function, "remoteDataFetchFailed")
            return errorView.toAnyView()
        }
    }
}