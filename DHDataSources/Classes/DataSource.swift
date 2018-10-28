import Foundation

public protocol DataSource: AnyObject {
    associatedtype ModelType
    
    func numberOfSections() -> Int
    func numberOfItemsInSection(_ section: Int) -> Int
    func totalNumberOfItems() -> Int
    subscript(indexPath: IndexPath) -> ModelType { get }
    
    func subscribe(observer: DataSourceChangeObserver, ignoreChangeTypes: [ChangeType], indexPathOffset: IndexPath)
    func unsubscribe(observer: DataSourceChangeObserver)
}

public protocol DataSourceChangeObserver: AnyObject {
    func dataSourceDidChange(objectChanges: [ObjectChangeTuple], sectionChanges: [SectionChangeTuple])
    func reloadAllItems()
}

public enum ChangeType : UInt {
    case insert
    case delete
    case move
    case update
}

public typealias SectionChangeTuple = (changeType: ChangeType, sectionIndex: Int)
public typealias ObjectChangeTuple = (changeType: ChangeType, indexPaths: [IndexPath])
