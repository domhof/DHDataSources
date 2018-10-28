import Foundation
import CoreData

open class FetchedResultsControllerDataSource<ModelType: NSFetchRequestResult>: DataSource {
    
    public let fetchedResultsController: NSFetchedResultsController<ModelType>
    
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
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreChangeTypes: [ChangeType], indexPathOffset: IndexPath) {
        fatalError("Not implemented")
    }
    
    public func unsubscribe(observer: DataSourceChangeObserver) {
        fatalError("Not implemented")
    }
}

public class FetchedResultsControllerChangeObserver<ModelType: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
    
    private unowned let dataSource: FetchedResultsControllerDataSource<ModelType>
    
    private var changeObservers = [(dataSourceChangeObserver: DataSourceChangeObserver, indexPathOffset: IndexPath, ignoreChangeTypes: [ChangeType])]()
    
    public init(dataSource: FetchedResultsControllerDataSource<ModelType>) {
        self.dataSource = dataSource
    }
    
    deinit {
        if dataSource.fetchedResultsController.delegate === self {
            dataSource.fetchedResultsController.delegate = nil
        }
    }
    
    fileprivate func subscribe(observer: DataSourceChangeObserver, indexPathOffset: IndexPath = IndexPath(item: 0, section: 0), ignoreChangeTypes: [ChangeType]) {
        #warning("Use lock to prevent concurrent access.")
        
        changeObservers.append((observer, indexPathOffset, ignoreChangeTypes))
        
        if (changeObservers.count == 1) {
            activate()
        }
    }
    
    fileprivate func unsubscribe(observer: DataSourceChangeObserver) {
        #warning("Use lock to prevent concurrent access.")
        
        if let i = changeObservers.firstIndex(where: { $0.dataSourceChangeObserver === observer }) {
            changeObservers.remove(at: i)
            
            if changeObservers.isEmpty {
                deactivate()
            }
        }
    }
    
    private func activate() {
        if dataSource.fetchedResultsController.delegate === self {
            return
        }
        guard dataSource.fetchedResultsController.delegate == nil else {
            assertionFailure("Tried to activate FetchedResultsControllerChangeObserver while another observer is active.")
            return
        }
        dataSource.fetchedResultsController.delegate = self
    }
    
    private func deactivate() {
        guard dataSource.fetchedResultsController.delegate === self else {
            assertionFailure("Tried to deactivate FetchedResultsControllerChangeObserver although it was not active.")
            return
        }
        dataSource.fetchedResultsController.delegate = nil
    }
    
    private var sectionChanges = [SectionChangeTuple]()
    private var objectChanges = [ObjectChangeTuple]()
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
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
        for (observer, indexPathOffset, ignoreChangeTypes) in changeObservers {
            if !ignoreChangeTypes.isEmpty {
                let filterdSectionChanges: [SectionChangeTuple]
                let filterdObjectChanges: [ObjectChangeTuple]
                if indexPathOffset == IndexPath(item: 0, section: 0) {
                    filterdObjectChanges = objectChanges.filter { !ignoreChangeTypes.contains($0.changeType) }
                    filterdSectionChanges = sectionChanges.filter { !ignoreChangeTypes.contains($0.changeType) }
                } else {
                    filterdObjectChanges = objectChanges.compactMap({ objectChangeTuple -> ObjectChangeTuple? in
                        if ignoreChangeTypes.contains(objectChangeTuple.changeType) {
                            return nil
                        } else {
                            let indexPaths = objectChangeTuple.indexPaths.map { IndexPath(item: $0.item + indexPathOffset.item, section: $0.section + indexPathOffset.section) }
                            return (objectChangeTuple.changeType, indexPaths)
                        }
                    })
                    filterdSectionChanges = sectionChanges.compactMap({ sectionChangeTuple -> SectionChangeTuple? in
                        if ignoreChangeTypes.contains(sectionChangeTuple.changeType) {
                            return nil
                        } else {
                            return (sectionChangeTuple.changeType, sectionChangeTuple.sectionIndex + indexPathOffset.section)
                        }
                    })
                }
                
                observer.dataSourceDidChange(objectChanges: filterdObjectChanges, sectionChanges: filterdSectionChanges)
            } else {
                observer.dataSourceDidChange(objectChanges: objectChanges, sectionChanges: sectionChanges)
            }
        }
        sectionChanges.removeAll()
        objectChanges.removeAll()
    }
}
