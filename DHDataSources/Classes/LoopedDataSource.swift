import Foundation

public class LoopedDataSource<DataSourceType: DataSource>: NSObject, DataSource {
    
    private let dataSource: DataSourceType
    private let sectionsLoopCount: Int
    private let itemsLoopCount: Int
    
    public enum LoopType {
        case section
        case items
    }
    
    public init(dataSource: DataSourceType, sectionsLoopCount: Int, itemsLoopCount: Int) {
        precondition(sectionsLoopCount >= 0)
        precondition(itemsLoopCount >= 0)
        
        self.dataSource = dataSource
        self.sectionsLoopCount = sectionsLoopCount
        self.itemsLoopCount = itemsLoopCount
    }
    
    public func numberOfSections() -> Int {
        return dataSource.numberOfSections() * (sectionsLoopCount + 1)
    }
    
    public func numberOfItemsInSection(_ section: Int) -> Int {
        return dataSource.numberOfItemsInSection(section) * (itemsLoopCount + 1)
    }
    
    public func totalNumberOfItems() -> Int {
        return (0 ... numberOfSections() - 1).reduce(0) { (count, section) -> Int in
            return count + numberOfItemsInSection(section)
        }
    }
    
    public subscript(indexPath: IndexPath) -> DataSourceType.ModelType {
        get {
            let section = indexPath.section % dataSource.numberOfSections()
            let item = indexPath.item % dataSource.numberOfItemsInSection(section)
            
            return dataSource[IndexPath(item:  item, section: section)]
        }
    }
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreObjectChangeTypes: [ObjectChange.ChangeType], ignoreSectionChangeTypes: [SectionChange.ChangeType], indexPathOffset: IndexPath) {
        dataSource.subscribe(observer: observer, ignoreObjectChangeTypes: ignoreObjectChangeTypes, ignoreSectionChangeTypes: ignoreSectionChangeTypes, indexPathOffset: indexPathOffset)
    }
    
    public func unsubscribe(observer: DataSourceChangeObserver) {
        dataSource.unsubscribe(observer: observer)
    }
}
