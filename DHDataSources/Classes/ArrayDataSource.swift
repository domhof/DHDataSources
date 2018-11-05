import Foundation

open class ArrayDataSource<ModelType>: NSObject, DataSource {
    
    public private (set) var sections: [[ModelType]]
    private let observerContainer = ObserverContainer()
    
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
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreChangeTypes: [ChangeType] = [], indexPathOffset: IndexPath) {
        observerContainer.add(observer: observer, ignoreChangeTypes: ignoreChangeTypes, indexPathOffset: indexPathOffset)
    }
    
    public func unsubscribe(observer: DataSourceChangeObserver) {
        observerContainer.remove(observer: observer)
    }
    
    // ArrayDataSource specific
    
    public func section(at index: Int) -> [ModelType] {
        return sections[index]
    }
    
    public func reset(newSections: [[ModelType]]) {
        self.sections = newSections
        observerContainer.reloadAllItems()
    }
    
    #warning("TODO: Do not require sections as an argument")
    public func applyChanges(sections: [[ModelType]], objectChanges: [ObjectChangeTuple], sectionChanges: [SectionChangeTuple]) {
        self.sections = sections
        observerContainer.dataSourceDidChange(objectChanges: objectChanges, sectionChanges: sectionChanges)
    }
}

public class ArrayDataSourceSorter<ModelType: Equatable> {
    
    let dataSource: ArrayDataSource<ModelType>
    let comparator: (_ item1: ModelType, _ item1: ModelType) -> ComparisonResult
    
    public init(dataSource: ArrayDataSource<ModelType>, comparator: @escaping (_ item1: ModelType, _ item2: ModelType) -> ComparisonResult) {
        self.dataSource = dataSource
        self.comparator = comparator
    }
    
    public func sort() {
        let numberOfSections = dataSource.numberOfSections()
        guard numberOfSections > 0 else { return }
        
        var sections = [[ModelType]]()
        var objectChanges = [ObjectChangeTuple]()
        
        for sectionIndex in 0..<numberOfSections {
            let originalArray = dataSource.section(at: sectionIndex)
            
            // Calculate new array.
            let sortedArray = (originalArray as NSArray).sortedArray(comparator: { (item1, item2) -> ComparisonResult in
                return comparator(item1 as! ModelType, item2 as! ModelType)
            }) as! [ModelType]
            sections[sectionIndex] = sortedArray
            
            // Calculate ObjectChangeTuples.
            for (originalIndex, originalItem) in originalArray.enumerated() {
                let sortedIndex = sortedArray.index(of: originalItem)!
                if originalIndex != sortedIndex {
                    let from = IndexPath(item: originalIndex, section: 0)
                    let to = IndexPath(item: sortedIndex, section: 0)
                    objectChanges.append(ObjectChangeTuple(changeType: .move, indexPaths:[from, to]))
                }
            }
        }
        
        dataSource.applyChanges(sections: sections, objectChanges: objectChanges, sectionChanges: [])
    }
}
