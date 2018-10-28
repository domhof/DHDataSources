import Foundation
import CoreData

public protocol UpdateableView: NSObjectProtocol {
    func applyChanges(objectChanges: [ObjectChangeTuple], sectionChanges: [SectionChangeTuple])
    
    func reloadAllItems()
}

extension UITableView: UpdateableView {
    
    public func applyChanges(objectChanges: [ObjectChangeTuple], sectionChanges: [SectionChangeTuple]) {
        beginUpdates()
        
        // Apply object changes.
        for (changeType, indexPaths) in objectChanges {
            switch(changeType) {
            case .insert:
                insertRows(at: indexPaths, with: .automatic)
            case .delete:
                deleteRows(at: indexPaths, with: .automatic)
            case .update:
                reloadRows(at: indexPaths, with: .automatic)
            case .move:
                if let deleteIndexPath = indexPaths.first {
                    deleteRows(at: [deleteIndexPath], with: .automatic)
                }
                
                if let insertIndexPath = indexPaths.last {
                    insertRows(at: [insertIndexPath], with: .automatic)
                }
            }
        }
        
        // Apply section changes.
        for (changeType, sectionIndex) in sectionChanges {
            let section = IndexSet(integer: sectionIndex)
            
            switch(changeType) {
            case .insert:
                insertSections(section, with: .automatic)
            case .delete:
                deleteSections(section, with: .automatic)
            default:
                break
            }
        }
        
        if sectionChanges.count > 0 {
            self.reloadAllItems()
        }
        
        endUpdates()
    }
    
    public func reloadAllItems() {
        self.reloadData()
    }
}

extension UICollectionView: UpdateableView {
    
    public func applyChanges(objectChanges: [ObjectChangeTuple], sectionChanges: [SectionChangeTuple]) {
        performBatchUpdates({
            // Apply object changes.
            for (changeType, indexPaths) in objectChanges {
                
                switch(changeType) {
                case .insert:
                    self.insertItems(at: indexPaths)
                case .delete:
                    self.deleteItems(at: indexPaths)
                case .update:
                    self.reloadItems(at: indexPaths)
                case .move:                    
                    self.moveItem(at: indexPaths.first!, to: indexPaths.last!)
                }
            }
            
            // Apply section changes.
            for (changeType, sectionIndex) in sectionChanges {
                let section = IndexSet(integer: sectionIndex)
                
                switch(changeType) {
                case .insert:
                    self.insertSections(section)
                case .delete:
                    self.deleteSections(section)
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
        self.reloadData()
        resetCacheIfNecessacry()
    }
    
    func resetCacheIfNecessacry() {
        // TODO
//        if let delegate = self.delegate {
//            if delegate.isKind(of: PreHeatingCollectionViewController.self) {
//                (delegate as! PreHeatingCollectionViewController).preheater.resetCachedAssets()
//            }
//        }
    }
}

// MARK: Change observers

//public protocol ChangeObserver {
//    func activate()
//    func deactivate()
//}



// MARK: Sorting

protocol DataSourceSorter {
    func sort()
}

public class ArrayDataSourceSorter<ModelType: Equatable>: DataSourceSorter {
    
    let view: UpdateableView
    let dataSource: ArrayDataSource<ModelType>
    let comparator: (_ item1: ModelType, _ item1: ModelType) -> ComparisonResult
    
    public init(view: UpdateableView, dataSource: ArrayDataSource<ModelType>, comparator: @escaping (_ item1: ModelType, _ item2: ModelType) -> ComparisonResult) {
        self.view = view
        self.dataSource = dataSource
        self.comparator = comparator
    }
    
    public func sort() {
        var objectChanges = [ObjectChangeTuple]()
        dataSource.sections.enumerated().forEach { (index, originalArray) in
            let sortedArray = (originalArray as NSArray).sortedArray(comparator: { (item1, item2) -> ComparisonResult in
                return comparator(item1 as! ModelType, item2 as! ModelType)
            }) as! [ModelType]
            dataSource.sections[index] = sortedArray
            
            for (originalIndex, originalItem) in originalArray.enumerated() {
                let sortedIndex = sortedArray.index(of: originalItem)!
                if originalIndex != sortedIndex {
                    let from = IndexPath(item: originalIndex, section: 0)
                    let to = IndexPath(item: sortedIndex, section: 0)
                    objectChanges.append(ObjectChangeTuple(changeType: .move, indexPaths:[from, to]))
                }
            }
        }
        view.applyChanges(objectChanges: objectChanges, sectionChanges: [])
    }
}
