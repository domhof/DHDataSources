import Foundation

public class CollectionViewUpdater: DataSourceChangeObserver {
    
    private let collectionView: UICollectionView
    
    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    
    public func dataSourceDidChange(objectChanges: [ObjectChange], sectionChanges: [SectionChange]) {
        collectionView.performBatchUpdates({
            // Apply object changes.
            for change in objectChanges {
                switch(change) {
                case let .insert(at: indexPath):
                    self.collectionView.insertItems(at: [indexPath])
                case let .delete(at: indexPath):
                    self.collectionView.deleteItems(at: [indexPath])
                case let .update(at: indexPath):
                    self.collectionView.reloadItems(at: [indexPath])
                case let .move(at: at, to: to):
                    self.collectionView.moveItem(at: at, to: to)
                }
            }
            
            // Apply section changes.
            for change in sectionChanges {
                switch(change) {
                case let .insert(at: sectionIndex):
                    self.collectionView.insertSections(IndexSet(integer: sectionIndex))
                case let .delete(at: sectionIndex):
                    self.collectionView.deleteSections(IndexSet(integer: sectionIndex))
                }
            }
        }) { _ in
            if sectionChanges.count > 0 {
                self.reloadAllItems()
            }
        }
    }
    
    public func reloadAllItems() {
        collectionView.reloadData()
    }
}
