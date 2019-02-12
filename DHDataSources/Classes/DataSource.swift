import Foundation

public protocol DataSource: AnyObject {
    associatedtype ModelType
    
    func numberOfSections() -> Int
    func numberOfItemsInSection(_ section: Int) -> Int
    func totalNumberOfItems() -> Int
    subscript(indexPath: IndexPath) -> ModelType { get }
    
    func subscribe(observer: DataSourceChangeObserver, ignoreObjectChangeTypes: [ObjectChange.ChangeType], ignoreSectionChangeTypes: [SectionChange.ChangeType], indexPathOffset: IndexPath)
    func unsubscribe(observer: DataSourceChangeObserver)
}

public protocol DataSourceChangeObserver: AnyObject {
    func dataSourceDidChange(objectChanges: [ObjectChange], sectionChanges: [SectionChange])
    func reloadAllItems()
}

public enum ObjectChange {
    case insert(at: IndexPath)
    case delete(at: IndexPath)
    case update(at: IndexPath)
    case move(at: IndexPath, to: IndexPath)
    
    public var type: ChangeType {
        switch self {
        case .delete: return .delete
        case .insert: return .insert
        case .update: return .update
        case .move: return .move
        }
    }
    
    public enum ChangeType: UInt {
        case insert
        case delete
        case update
        case move
    }
    
    func adding(offset: IndexPath) -> ObjectChange {
        switch self {
        case let .delete(at: indexPath): return .delete(at: IndexPath(item: indexPath.item + offset.item, section: indexPath.section + offset.section))
        case let .insert(at: indexPath): return .insert(at: IndexPath(item: indexPath.item + offset.item, section: indexPath.section + offset.section))
        case let .update(at: indexPath): return .update(at: IndexPath(item: indexPath.item + offset.item, section: indexPath.section + offset.section))
        case let .move(at: at, to: to): return .move(at: IndexPath(item: at.item + offset.item, section: at.section + offset.section), to: IndexPath(item: to.item + offset.item, section: to.section + offset.section))
        }
    }
}

public enum SectionChange {
    public typealias Index = Int
    
    case insert(at: Index)
    case delete(at: Index)
    
    public var type: ChangeType {
        switch self {
        case .delete: return .delete
        case .insert: return .insert
        }
    }
    
    public enum ChangeType: UInt {
        case insert
        case delete
    }
    
    func adding(offset: Index) -> SectionChange {
        switch self {
        case let .delete(at: index): return .delete(at: index + offset)
        case let .insert(at: index): return .insert(at: index + offset)
        }
    }
}
