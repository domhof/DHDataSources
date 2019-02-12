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
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreObjectChangeTypes: [ObjectChange.ChangeType] = [], ignoreSectionChangeTypes: [SectionChange.ChangeType] = [], indexPathOffset: IndexPath = IndexPath(item: 0, section: 0)) {
        fetchedResultsChangeObserver.subscribe(observer: observer, ignoreObjectChangeTypes: ignoreObjectChangeTypes, ignoreSectionChangeTypes: ignoreSectionChangeTypes, indexPathOffset: indexPathOffset)
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
    
    fileprivate func subscribe(observer: DataSourceChangeObserver, ignoreObjectChangeTypes: [ObjectChange.ChangeType], ignoreSectionChangeTypes: [SectionChange.ChangeType], indexPathOffset: IndexPath) {
        observerContainer.add(observer: observer, ignoreObjectChangeTypes: ignoreObjectChangeTypes, ignoreSectionChangeTypes: ignoreSectionChangeTypes, indexPathOffset: indexPathOffset) {
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
    
    private var sectionChanges = [SectionChange]()
    private var objectChanges = [ObjectChange]()
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Do nothing...
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            sectionChanges.append(SectionChange.insert(at: sectionIndex))
        case .delete:
            sectionChanges.append(SectionChange.delete(at: sectionIndex))
        default:
            assertionFailure("Invalid section change type.")
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            objectChanges.append(.insert(at: newIndexPath!))
        case .delete:
            objectChanges.append(.delete(at: indexPath!))
        case .update:
            objectChanges.append(.update(at: newIndexPath!))
        case .move:
            objectChanges.append(.move(at: indexPath!, to: newIndexPath!))
        }
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        // http://www.openradar.me/27957917
//        NSLog("before: \(objectChanges)")
//        // Remove all .update for which there is another change concerning the same index.
//        let nonUpdates = objectChanges.filter { (change) -> Bool in
//            if case ObjectChange.update = change {
//                return false
//            } else {
//                return true
//            }
//        }
//        if !nonUpdates.isEmpty && nonUpdates.count != objectChanges.count {
//            objectChanges.removeAll { change -> Bool in
//                guard case ObjectChange.update(at: let indexPath) = change else { return false }
//                return nonUpdates.contains(where: {
//                    switch $0 {
//                    case .delete(at: indexPath): return true
//                    case .insert(at: indexPath): return true
//                    case .move(at: indexPath, to: _): return true
//                    case .move(at: _, to: indexPath): return true
//                    default: return false
//                    }
//                })
//            }
//        }
//        NSLog("after: \(objectChanges)")
        observerContainer.dataSourceDidChange(objectChanges: objectChanges, sectionChanges: sectionChanges)
        
        sectionChanges.removeAll()
        objectChanges.removeAll()
    }
}
