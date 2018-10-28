import Foundation

public class ArrayDataSource<ModelType>: NSObject, DataSource {
    
    public var sections: [[ModelType]]
    
    public init(items: [ModelType]) {
        self.sections = [items]
    }
    
    public init(sections: [[ModelType]]) {
        self.sections = sections
    }
    
    public func numberOfSections() -> Int {
        return sections.count
    }
    
    public func numberOfItemsInSection(_ section: Int) -> Int {
        return sections[section].count
    }
    
    public func totalNumberOfItems() -> Int {
        return sections.map{ $0.count }.reduce(0, +)
    }
    
    public subscript(indexPath: IndexPath) -> ModelType {
        get {
            return sections[indexPath.section][indexPath.item]
        }
    }
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreChangeTypes: [ChangeType], indexPathOffset: IndexPath) {
        fatalError("not implemented")
    }
    
    public func unsubscribe(observer: DataSourceChangeObserver) {
        fatalError("not implemented")
    }
}
