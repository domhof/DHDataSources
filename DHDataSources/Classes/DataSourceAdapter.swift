import Foundation

public class DataSourceAdapter<DataSourceType: DataSource, Model>: DataSource {
    
    public typealias ModelType = Model
    public typealias Mapping = (DataSourceType.ModelType) -> Model
    
    private let dataSource: DataSourceType
    private let mapping: Mapping
    
    public init(dataSource: DataSourceType, mapping: @escaping Mapping) {
        self.dataSource = dataSource
        self.mapping = mapping
    }
    
    public func numberOfSections() -> Int {
        return dataSource.numberOfSections()
    }
    
    public func numberOfItemsInSection(_ section: Int) -> Int {
        return dataSource.numberOfItemsInSection(section)
    }
    
    public func totalNumberOfItems() -> Int {
        return dataSource.totalNumberOfItems()
    }
    
    public subscript(indexPath: IndexPath) -> Model {
        return mapping(dataSource[indexPath])
    }
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreChangeTypes: [ChangeType] = [], indexPathOffset: IndexPath = IndexPath(item: 0, section: 0)) {
        dataSource.subscribe(observer: observer, ignoreChangeTypes: ignoreChangeTypes, indexPathOffset: indexPathOffset)
    }
    
    public func unsubscribe(observer: DataSourceChangeObserver) {
        dataSource.unsubscribe(observer: observer)
    }
}
