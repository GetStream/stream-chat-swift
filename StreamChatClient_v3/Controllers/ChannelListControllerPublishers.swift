//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Combine
import UIKit

@available(iOS 13, *)
extension Client {
    /// Creates a new `ChannelListController.Publishers` object with the provided channel query.
    ///
    /// - Parameter query: The query specify the filter and sorting of the channels the controller should fetch.
    /// - Returns: A new instance of `ChannelListController.Publishers`.
    ///
    @available(iOS 13, *)
    public func channelListControllerPublishers(query: ChannelListQuery) -> ChannelListControllerGeneric<ExtraData>.Publishers {
        let controller = ChannelListControllerGeneric(query: query, client: self)
        return .init(controller: controller)
    }
}

/// Describes possible states of Controller's remote activity.
public enum RemoteActivity {
    /// The controller is not listening for updates. Call `startUpdating` to fetch the remote data and start listening for changes.
    case none
    
    /// Controller actively tries to refresh the local data.
    case fetchingRemoteData
    
    /// Controller is listening for incoming changes.
    case listening
    
    /// Remote data fetch failed. Controller might still be able to show the recent incoming changes, but it's possible
    /// the presented data are not complete.
    case failed(error: Error?)
}

@available(iOS 13, *)
extension ChannelListControllerGeneric {
    /// An object which wraps `ChannelListController` and exposes its properties as Publishers.
    public class Publishers {
        /// Publishes changes to the remote activity state. You can use this publisher to show activity indicator to users
        /// if the controller is fetching the remote data.
        public var remoteActivityPublisher: AnyPublisher<RemoteActivity, Never> {
            remoteActivity
                // Is something like this the way to keep `Publishers` object alive if there is a subscriber?
                .map { [self] in _ = self; return $0 }
                .eraseToAnyPublisher()
        }
        
        /// Publishes the changes to the list of channels matching the query. You can use this publisher to animate changes
        /// to the channel list, or to simply reload all your the data.
        ///
        /// Alternatively, you can use `channelsDiffableDatasourcePublisher` which provides similar functionality using the
        /// `NSDiffableDataSource` API.
        ///
        /// - Note: ⚠️ The publisher publishes only **changes** to the list of channels. Use the `channels` property to load
        /// the initial data before subscribing to the publisher.
        public var channelChangesPublisher: AnyPublisher<[Change<ChannelModel<ExtraData>>], Never> {
            channelChanges
                .map { [self] in _ = self; return $0 }
                .eraseToAnyPublisher()
        }
        
        // TODO: Implement
        public var channelsDiffableDatasourcePublisher:
            AnyPublisher<NSDiffableDataSourceSnapshot<ChannelListSection, ChannelModel<ExtraData>>, Never>! = nil
        
        /// The channels matching the query. If you want to react to changes in this field, subscribe to `channelChanges` publisher.
        public var channels: [ChannelModel<ExtraData>] {
            // Start observing changes if needed
            if controller.state == .idle {
                controller.startUpdating()
            }
            
            return controller.channels
        }
        
        /// The underlying controller instance of this wrapper.
        let controller: ChannelListControllerGeneric
        
        /// A backing subject for `remoteActivityPublisher`.
        private let remoteActivity: CurrentValueSubject<RemoteActivity, Never> = .init(.none)
        
        /// A backing subject for `channelChangesPublisher`.
        private let channelChanges: PassthroughSubject<[Change<ChannelModel<ExtraData>>], Never> = .init()
        
        /// Creates a new `ChannelListControllerGeneric.Publishers` object.
        /// - Parameter controller: The controller instance this wrapper wraps. The wrapper sets itself as the controller's
        /// delegate, so be sure you always provide a fresh instance of the controller to the wrapper.
        init(controller: ChannelListControllerGeneric) {
            self.controller = controller
            controller.setDelegate(self)
        }
    }
}

// TODO: for diffable datasource
public enum ChannelListSection {
    case main
}

@available(iOS 13, *)
extension ChannelListControllerGeneric.Publishers: ChannelListControllerDelegateGeneric {
    public func controllerWillStartFetchingRemoteData(_ controller: Controller) {
        remoteActivity.send(.fetchingRemoteData)
    }
    
    public func controllerDidStopFetchingRemoteData(_ controller: Controller, withError error: Error?) {
        if let error = error {
            remoteActivity.send(.failed(error: error))
        } else {
            remoteActivity.send(.listening)
        }
    }
    
    public func controller(_ controller: ChannelListControllerGeneric<ExtraData>,
                           didChangeChannels changes: [Change<ChannelModel<ExtraData>>]) {
        channelChanges.send(changes)
    }
}
