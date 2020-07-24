//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// `ChannelController` allows observing and mutating the controlled channel.
///
///  ... you can do this and that
///
public class ChannelController<ExtraData: ExtraDataTypes>: Controller {
    public let channelId: ChannelId
    public weak var delegate: ChannelControllerDelegate?
    
    private let viewContext: NSManagedObjectContext
    private let worker: ChannelUpdater<ExtraData>
    
    private lazy var fetchResultsController: NSFetchedResultsController<ChannelDTO> = {
        let request = ChannelDTO.fetchRequest(for: channelId)
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: viewContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self.changeAggregator
        return frc
    }()
    
    /// Acts like the `NSFetchedResultsController`'s delegate and aggregates the reported changes into easily consumable form.
    private(set) lazy var changeAggregator: ChangeAggregator<ChannelDTO, ChannelModel<ExtraData>> = {
        let aggregator: ChangeAggregator<ChannelDTO, ChannelModel<ExtraData>> = .init(itemCreator: ChannelModel<ExtraData>.create)
        
        aggregator.onChange = { [unowned self] (_: [Change<ChannelModel<ExtraData>>]) in
            guard let channel = self.fetchResultsController.fetchedObjects?.first
                .map(ChannelModel<ExtraData>.create(fromDTO:)) else { return }
            
            self.delegate?.channelController(self, didUpdateChannel: channel)
        }
        
        return aggregator
    }()
    
    init(channelId: ChannelId, worker: ChannelUpdater<ExtraData>, viewContext: NSManagedObjectContext) {
        self.channelId = channelId
        self.worker = worker
        self.viewContext = viewContext
    }
    
    public func startUpdating() {
        try! fetchResultsController.performFetch()
        
        guard let channel = fetchResultsController.fetchedObjects?.first
            .map(ChannelModel<ExtraData>.create(fromDTO:)) else { return }
        delegate?.channelController(self, didUpdateChannel: channel)
        
        worker.update(channelQuery: .init(channelId: channelId))
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let channel = fetchResultsController.fetchedObjects?.first
            .map(ChannelModel<ExtraData>.create(fromDTO:)) else { return }
        delegate?.channelController(self, didUpdateChannel: channel)
    }
}

public protocol ChannelControllerDelegate: AnyObject {
    func channelController<ExtraData: ExtraDataTypes>(_ channelController: ChannelController<ExtraData>,
                                                      didUpdateChannel channel: ChannelModel<ExtraData>)
}

extension Client {
    /// Creates a new `ChannelController` for the channel with the provided id.
    ///
    /// - Parameter channelId: The id of the channel this controller represents.
    /// - Returns: A new instance of `ChannelController`.
    ///
    public func channelController(for channelId: ChannelId) -> ChannelController<ExtraData> {
        let worker = ChannelUpdater<ExtraData>(database: databaseContainer, webSocketClient: webSocketClient,
                                               apiClient: apiClient)
        return .init(channelId: channelId, worker: worker, viewContext: databaseContainer.viewContext)
    }
}
