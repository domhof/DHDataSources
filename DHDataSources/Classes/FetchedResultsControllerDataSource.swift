import Foundation
import CoreData

open class FetchedResultsControllerDataSource<ModelType: NSFetchRequestResult>: DataSource {
    
    public let fetchedResultsController: NSFetchedResultsController<ModelType>
    private lazy var fetchedResultsChangeObserver = FetchedResultsControllerChangeObserver<ModelType>(fetchedResultsController: self.fetchedResultsController)
    
    public init(fetchedResultsController: NSFetchedResultsController<ModelType>) {
        self.fetchedResultsController = fetchedResultsController
    }
    
    public func numberOfSections() -> Int {
        return fetchedResultsController.sections!.count
    }
    
    public func numberOfItemsInSection(_ section: Int) -> Int {
        let sections = fetchedResultsController.sections!
        return sections[section].numberOfObjects
    }
    
    public func totalNumberOfItems() -> Int {
        return (0 ... numberOfSections() - 1).reduce(0) { (count, section) -> Int in
            return count + numberOfItemsInSection(section)
        }
    }
    
    public subscript(indexPath: IndexPath) -> ModelType {
        get {
            return fetchedResultsController.object(at: indexPath)
        }
    }
    
    public func allItems() -> [ModelType] {
        return fetchedResultsController.fetchedObjects!
    }
    
    private var subscribers = [DataSourceChangeObserver]()
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreChangeTypes: [ChangeType] = [], indexPathOffset: IndexPath = IndexPath(item: 0, section: 0)) {
        fetchedResultsChangeObserver.subscribe(observer: observer, ignoreChangeTypes: ignoreChangeTypes, indexPathOffset: indexPathOffset)
    }
    
    public func unsubscribe(observer: DataSourceChangeObserver) {
        fetchedResultsChangeObserver.unsubscribe(observer: observer)
    }
}

fileprivate class FetchedResultsControllerChangeObserver<ModelType: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
    
    private let fetchedResultsController: NSFetchedResultsController<ModelType>
    private let observerContainer = ObserverContainer()
    
    public init(fetchedResultsController: NSFetchedResultsController<ModelType>) {
        self.fetchedResultsController = fetchedResultsController
    }
    
    deinit {
        if fetchedResultsController.delegate === self {
            fetchedResultsController.delegate = nil
        }
    }
    
    fileprivate func subscribe(observer: DataSourceChangeObserver, ignoreChangeTypes: [ChangeType], indexPathOffset: IndexPath) {
        observerContainer.add(observer: observer, ignoreChangeTypes: ignoreChangeTypes, indexPathOffset: indexPathOffset) {
            self.activate()
        }
    }
    
    fileprivate func unsubscribe(observer: DataSourceChangeObserver) {
        observerContainer.remove(observer: observer) {
            self.deactivate()
        }
    }
    
    private func activate() {
        if fetchedResultsController.delegate === self {
            return
        }
        guard fetchedResultsController.delegate == nil else {
            assertionFailure("Tried to activate FetchedResultsControllerChangeObserver while another observer is active.")
            return
        }
        fetchedResultsController.delegate = self
    }
    
    private func deactivate() {
        guard fetchedResultsController.delegate === self else {
            assertionFailure("Tried to deactivate FetchedResultsControllerChangeObserver although it was not active.")
            return
        }
        fetchedResultsController.delegate = nil
    }
    
    private var sectionChanges = [SectionChangeTuple]()
    private var objectChanges = [ObjectChangeTuple]()
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Do nothing...
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        sectionChanges.append((translateChangeType(type), sectionIndex))
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let changeType = translateChangeType(type)
        
        switch type {
        case .insert:
            if let insertIndexPath = newIndexPath {
                objectChanges.append((changeType, [insertIndexPath]))
            }
        case .delete:
            if let deleteIndexPath = indexPath {
                objectChanges.append((changeType, [deleteIndexPath]))
            }
        case .update:
            if let indexPath = indexPath {
                objectChanges.append((changeType, [indexPath]))
            }
        case .move:
            if let old = indexPath, let new = newIndexPath {
                objectChanges.append((changeType, [old, new]))
            }
        }
    }
    
    private func translateChangeType(_ type: NSFetchedResultsChangeType) -> ChangeType {
        switch type {
        case .insert:
            return .insert
        case .delete:
            return .delete
        case .update:
            return .update
        case .move:
            return .move
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observerContainer.dataSourceDidChange(objectChanges: objectChanges, sectionChanges: sectionChanges)
        
        sectionChanges.removeAll()
        objectChanges.removeAll()
    }
}
