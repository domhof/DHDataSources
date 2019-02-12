import Foundation
import Photos

public class PHFetchResultDataSource<ModelType: PHObject>: DataSource {
    
    public var fetchResult: PHFetchResult<ModelType>
    private lazy var photoLibraryChangeObserver = PhotoLibraryChangeObserver<ModelType>(dataSource: self)
    
    public init(fetchResult: PHFetchResult<ModelType>) {
        self.fetchResult = fetchResult
    }
    
    public func numberOfSections() -> Int {
        return 1
    }
    
    public func numberOfItemsInSection(_ section: Int) -> Int {
        return fetchResult.count
    }
    
    public func totalNumberOfItems() -> Int {
        return fetchResult.count
    }
    
    public subscript(indexPath: IndexPath) -> ModelType {
        get {
            if indexPath.section != 0 {
                fatalError("Section must be 0")
            }
            
            return fetchResult[indexPath.item]
        }
    }
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreObjectChangeTypes: [ObjectChange.ChangeType] = [], ignoreSectionChangeTypes: [SectionChange.ChangeType] = [], indexPathOffset: IndexPath = IndexPath(item: 0, section: 0)) {
        #warning("ignoreChangeTypes gets ignored for the time being...")
        
        photoLibraryChangeObserver.subscribe(observer: observer, indexPathOffset: indexPathOffset)
    }
    
    public func unsubscribe(observer: DataSourceChangeObserver) {
        photoLibraryChangeObserver.unsubscribe(observer: observer)
    }
}

#warning("Remove and let client register a DataSourceChangeObserver instead.")

public protocol PhotoLibraryChangeObserverDelegate: class {
    func photoLibraryChangeObserverDataDidChange()
}

#warning("TODO: Use ObserverContainer")
fileprivate class PhotoLibraryChangeObserver<ModelType: PHObject>: NSObject, PHPhotoLibraryChangeObserver {
    
    public weak var delegate: (PhotoLibraryChangeObserverDelegate)?
    
    private unowned let dataSource: PHFetchResultDataSource<ModelType>
    
    private var changeObservers = [(dataSourceChangeObserver: DataSourceChangeObserver, indexPathOffset: IndexPath)]()
    
    private let phPhotoLibChageMutex = DispatchSemaphore(value: 1)
    
    fileprivate init(dataSource: PHFetchResultDataSource<ModelType>) {
        self.dataSource = dataSource
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    fileprivate func subscribe(observer: DataSourceChangeObserver, indexPathOffset: IndexPath = IndexPath(item: 0, section: 0)) {
        #warning("Use lock to prevent concurrent access.")
        
        changeObservers.append((observer, indexPathOffset))
        
        if (changeObservers.count == 1) {
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    fileprivate func unsubscribe(observer: DataSourceChangeObserver) {
        #warning("Use lock to prevent concurrent access.")
        if let i = changeObservers.firstIndex(where: { $0.dataSourceChangeObserver === observer }) {
            changeObservers.remove(at: i)
            if changeObservers.isEmpty {
                PHPhotoLibrary.shared().unregisterChangeObserver(self)
            }
        }
    }
    
    private func reloadAllItems() {
        // Photos may call this method on a background queue;
        // switch to the main queue to update the UI.
        DispatchQueue.main.async {
            self.changeObservers.forEach { $0.dataSourceChangeObserver.reloadAllItems() }
        }
    }
    
    private func dataSourceDidChange(collectionChanges: PHFetchResultChangeDetails<ModelType>) {
        #warning("Use lock to prevent concurrent access.")
        
        for (observer, indexPathOffset) in changeObservers {
            var objectChanges = [ObjectChange]()
            
            // Delete
            if let removed = collectionChanges.removedIndexes {
                for index in removed {
                    let indexPath = IndexPath(item: index + indexPathOffset.item, section: indexPathOffset.section)
                    objectChanges.append(ObjectChange.delete(at: indexPath))
                }
            }
            
            // Insert
            if let inserted = collectionChanges.insertedIndexes {
                for index in inserted {
                    let indexPath = IndexPath(item: index + indexPathOffset.item, section: indexPathOffset.section)
                    objectChanges.append(ObjectChange.insert(at: indexPath))
                }
            }
            
            // Update
            if let updated = collectionChanges.changedIndexes {
                for index in updated {
                    let indexPath = IndexPath(item: index + indexPathOffset.item, section: indexPathOffset.section)
                    objectChanges.append(ObjectChange.update(at: indexPath))
                }
            }
            
            // Move
            var moves = [IndexPath: IndexPath]()
            if (collectionChanges.hasMoves) {
                collectionChanges.enumerateMoves() { fromIndex, toIndex in
                    let fromIndexPath = IndexPath(item: fromIndex + indexPathOffset.item, section: indexPathOffset.section)
                    let toIndexPath = IndexPath(item: toIndex + indexPathOffset.item, section: indexPathOffset.section)
                    
                    if moves[fromIndexPath] != nil {
                        assertionFailure()
                    }
                    
                    moves[fromIndexPath] = toIndexPath
                    objectChanges.append(ObjectChange.move(at: fromIndexPath, to: toIndexPath))
                }
            }
            
            // Photos may call this method on a background queue;
            // switch to the main queue to update the UI.
            DispatchQueue.main.async {
                observer.dataSourceDidChange(objectChanges: objectChanges, sectionChanges: [])
            }
        }
    }
    
    public func photoLibraryDidChange(_ changeInfo: PHChange) {
        _ = phPhotoLibChageMutex.wait(timeout: DispatchTime.distantFuture) // TODO: Remove?
        
        // Check for changes to the list of assets (insertions, deletions, moves, or updates).
        //  as! PHFetchResult<PHObject> added as part of Swift 3 migration.
        if let collectionChanges = changeInfo.changeDetails(for: self.dataSource.fetchResult) {
            
            // Get the new fetch result for future change tracking.
            self.dataSource.fetchResult = collectionChanges.fetchResultAfterChanges
            
            if collectionChanges.hasIncrementalChanges {
                var shouldReload = false
                if
                    let removedIndexes = collectionChanges.removedIndexes,
                    let changedIndexes = collectionChanges.changedIndexes
                {
                    if removedIndexes.isDisjoint(with: changedIndexes) {
                        shouldReload = true
                    }
                    
                    if let last = removedIndexes.last, last >= collectionChanges.fetchResultBeforeChanges.count {
                        shouldReload = true
                        #warning("Handle error")
                        NSLog("removedPaths.last!.item >= collectionChanges.fetchResultBeforeChanges.count")
                    }
                }
                
                if shouldReload {
                    self.reloadAllItems()
                    self.delegate?.photoLibraryChangeObserverDataDidChange()
                    
                    self.phPhotoLibChageMutex.signal()
                } else {
                    // Tell the collection view to animate insertions/deletions/moves
                    // and to refresh any cells that have changed content.
                    
                    self.dataSourceDidChange(collectionChanges: collectionChanges)
                    self.delegate?.photoLibraryChangeObserverDataDidChange()
                    
                    self.phPhotoLibChageMutex.signal()
                }
            } else {
                // Detailed change information is not available;
                // repopulate the UI from the current fetch result.
                self.reloadAllItems()
                self.delegate?.photoLibraryChangeObserverDataDidChange()
                
                self.phPhotoLibChageMutex.signal()
            }
        } else {
            self.phPhotoLibChageMutex.signal()
        }
    }
}
