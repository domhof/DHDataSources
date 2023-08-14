import Foundation

public class CollectionViewUpdater: DataSourceChangeObserver {
    
    private weak var collectionView: UICollectionView?
    
    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    
    public func dataSourceDidChange(objectChanges: [ObjectChange], sectionChanges: [SectionChange]) {
        guard let collectionView = collectionView, collectionView.window != nil else { return }
        
        collectionView.performBatchUpdates({
            // Apply object changes.
            for change in objectChanges {
                switch(change) {
                case let .insert(at: indexPath):
                    collectionView.insertItems(at: [indexPath])
                case let .delete(at: indexPath):
                    collectionView.deleteItems(at: [indexPath])
                case let .update(at: indexPath):
                    collectionView.reloadItems(at: [indexPath])
                case let .move(at: at, to: to):
                    collectionView.moveItem(at: at, to: to)
                }
            }
            
            // Apply section changes.
            for change in sectionChanges {
                switch(change) {
                case let .insert(at: sectionIndex):
                    collectionView.insertSections(IndexSet(integer: sectionIndex))
                case let .delete(at: sectionIndex):
                    collectionView.deleteSections(IndexSet(integer: sectionIndex))
                }
            }
        }) { _ in
            if sectionChanges.count > 0 {
                self.reloadAllItems()
            }
        }
    }
    
    public func reloadAllItems() {
        collectionView?.reloadData()
    }
}
