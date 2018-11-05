import Foundation
import UIKit

public protocol CollectionViewDataSourceAdapterProtocol: UICollectionViewDataSource {
    
    func dataSourceForCollectionView(_ collectionView: UICollectionView, atIndexPath indexPath: IndexPath) -> (dataSource: AnyObject, convertedIndexPath: IndexPath)
    
    /// Connects a model at an indexPath to a cell at a different indexPath within the collectionView.
    func collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath, indexPathInCollectionView: IndexPath) -> UICollectionViewCell
}

open class CollectionViewDataSourceAdapter<DataSourceType: DataSource, ModelType>: NSObject, CollectionViewDataSourceAdapterProtocol where DataSourceType.ModelType == ModelType {
    
    public typealias CellProvider = (_ collectionView: UICollectionView, _ indexPath: IndexPath, _ model: ModelType) -> UICollectionViewCell
    
    private let dataSource: DataSourceType
    private let cellProvider: CellProvider
    
    public init(dataSource: DataSourceType, cellProvider: @escaping CellProvider) {
        self.dataSource = dataSource
        self.cellProvider = cellProvider
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfItemsInSection(section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = dataSource[indexPath]
        
        return cellProvider(collectionView, indexPath, model)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath, indexPathInCollectionView: IndexPath) -> UICollectionViewCell {
        return cellProvider(collectionView, indexPathInCollectionView, dataSource[indexPath])
    }
    
    public func dataSourceForCollectionView(_ collectionView: UICollectionView, atIndexPath indexPath: IndexPath) -> (dataSource: AnyObject, convertedIndexPath: IndexPath) {
        return (dataSource: dataSource, convertedIndexPath: indexPath)
    }
}

open class CombinedCollectionViewDataSourceAdapter: NSObject, CollectionViewDataSourceAdapterProtocol {
    
    let collectionViewDataSourceAdapters: [CollectionViewDataSourceAdapterProtocol]
    
    public init(collectionViewDataSourceAdapters: [CollectionViewDataSourceAdapterProtocol]) {
        self.collectionViewDataSourceAdapters = collectionViewDataSourceAdapters
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionViewDataSourceAdapters.reduce(0) { (count, adapter) -> Int in
            return count + adapter.numberOfSections!(in: collectionView)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let (adapter, section) = findAdapterForSection(section, inCollectionView: collectionView)
        return adapter.collectionView(collectionView, numberOfItemsInSection: section)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let (adapter, section) = findAdapterForSection(indexPath.section, inCollectionView: collectionView)
        return adapter.collectionView(collectionView, cellForItemAtIndexPath: IndexPath(item: indexPath.item, section: section), indexPathInCollectionView: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath, indexPathInCollectionView: IndexPath) -> UICollectionViewCell {
        let (adapter, section) = findAdapterForSection(indexPath.section, inCollectionView: collectionView)
        return adapter.collectionView(collectionView, cellForItemAtIndexPath: IndexPath(item: indexPath.item, section: section), indexPathInCollectionView: indexPathInCollectionView as IndexPath)
    }
    
    private func findAdapterForSection(_ section: Int, inCollectionView collectionView: UICollectionView) -> (adapter: CollectionViewDataSourceAdapterProtocol, section: Int) {
        var numberOfRemainingSections = section
        for adapter in collectionViewDataSourceAdapters {
            let numberOfSectionsInAdapter = adapter.numberOfSections!(in: collectionView)
            if numberOfRemainingSections < numberOfSectionsInAdapter {
                return (adapter: adapter, section: numberOfRemainingSections)
            } else {
                numberOfRemainingSections -= numberOfSectionsInAdapter
            }
        }
        fatalError("CombinedCollectionViewDataSourceAdapter inconsistency")
    }
    
    public func dataSourceForCollectionView(_ collectionView: UICollectionView, atIndexPath indexPath: IndexPath) -> (dataSource: AnyObject, convertedIndexPath: IndexPath) {
        let (adapter, section) = findAdapterForSection(indexPath.section, inCollectionView: collectionView)
        return adapter.dataSourceForCollectionView(collectionView, atIndexPath: IndexPath(item: indexPath.item, section: section))
    }
}

open class FlattenedCollectionViewDataSourceAdapter: NSObject, CollectionViewDataSourceAdapterProtocol {
    
    let collectionViewDataSourceAdapters: [CollectionViewDataSourceAdapterProtocol]
    
    public init(collectionViewDataSourceAdapters: [CollectionViewDataSourceAdapterProtocol]) {
        self.collectionViewDataSourceAdapters = collectionViewDataSourceAdapters
        super.init()
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionViewDataSourceAdapters.reduce(0) { (itemsCount, adapter) -> Int in
            return itemsCount + (0 ... adapter.numberOfSections!(in: collectionView) - 1).reduce(0) { (sectionCount, section) -> Int in
                return sectionCount + adapter.collectionView(collectionView, numberOfItemsInSection: section)
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.section == 0 else {
            fatalError("Section must be 0")
        }
        
        let (adapter, indexPathInAdapter) = adapterForCollectionView(collectionView, atIndexPath: indexPath)
        return adapter.collectionView(collectionView, cellForItemAtIndexPath: indexPathInAdapter, indexPathInCollectionView: indexPath)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath, indexPathInCollectionView: IndexPath) -> UICollectionViewCell {
        guard indexPath.section == 0 else {
            fatalError("Section must be 0")
        }
        
        let (adapter, indexPath) = adapterForCollectionView(collectionView, atIndexPath: indexPath)
        return adapter.collectionView(collectionView, cellForItemAtIndexPath: indexPath, indexPathInCollectionView: indexPathInCollectionView)
    }
    
    private func adapterForCollectionView(_ collectionView: UICollectionView, atIndexPath indexPath: IndexPath) -> (adapter: CollectionViewDataSourceAdapterProtocol, indexPath: IndexPath) {
        var numberOfRemainingItems = indexPath.item
        for adapter in collectionViewDataSourceAdapters {
            for section in 0 ... adapter.numberOfSections!(in: collectionView) {
                let numberOfItemsInSection = adapter.collectionView(collectionView, numberOfItemsInSection: section)
                if numberOfRemainingItems < numberOfItemsInSection {
                    return (adapter: adapter, indexPath: IndexPath(item: numberOfRemainingItems, section: section))
                } else {
                    numberOfRemainingItems -= numberOfItemsInSection
                }
            }
        }
        fatalError("FlattenedCollectionViewDataSourceAdapter inconsistency")
    }
    
    public func dataSourceForCollectionView(_ collectionView: UICollectionView, atIndexPath indexPath: IndexPath) -> (dataSource: AnyObject, convertedIndexPath: IndexPath) {
        let (adapter, convertedIndexPath) = adapterForCollectionView(collectionView, atIndexPath: indexPath)
        return adapter.dataSourceForCollectionView(collectionView, atIndexPath: convertedIndexPath)
    }
}
