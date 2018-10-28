import Foundation

public class CollectionViewUpdater<DataSourceType: DataSource>: DataSourceChangeObserver {
    
    private let dataSource: DataSourceType
    private let collectionView: UICollectionView
    
    init(dataSource: DataSourceType, collectionView: UICollectionView) {
        self.dataSource = dataSource
        self.collectionView = collectionView
    }
    
    public func dataSourceDidChange(objectChanges: [ObjectChangeTuple], sectionChanges: [SectionChangeTuple]) {
        collectionView.performBatchUpdates({
            // Apply object changes.
            for (changeType, indexPaths) in objectChanges {
                
                switch(changeType) {
                case .insert:
                    self.collectionView.insertItems(at: indexPaths)
                case .delete:
                    self.collectionView.deleteItems(at: indexPaths)
                case .update:
                    self.collectionView.reloadItems(at: indexPaths)
                case .move:
                    self.collectionView.moveItem(at: indexPaths.first!, to: indexPaths.last!)
                }
            }
            
            // Apply section changes.
            for (changeType, sectionIndex) in sectionChanges {
                let section = IndexSet(integer: sectionIndex)
                
                switch(changeType) {
                case .insert:
                    self.collectionView.insertSections(section)
                case .delete:
                    self.collectionView.deleteSections(section)
                default:
                    break
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
