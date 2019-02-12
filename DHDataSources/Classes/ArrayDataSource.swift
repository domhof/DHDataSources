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
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreObjectChangeTypes: [ObjectChange.ChangeType] = [], ignoreSectionChangeTypes: [SectionChange.ChangeType] = [], indexPathOffset: IndexPath = IndexPath(item: 0, section: 0)) {
        observerContainer.add(observer: observer, ignoreObjectChangeTypes: ignoreObjectChangeTypes, ignoreSectionChangeTypes: ignoreSectionChangeTypes, indexPathOffset: indexPathOffset)
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
    public func applyChanges(sections: [[ModelType]], objectChanges: [ObjectChange], sectionChanges: [SectionChange]) {
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
        var objectChanges = [ObjectChange]()
        
        for sectionIndex in 0..<numberOfSections {
            let originalArray = dataSource.section(at: sectionIndex)
            
            // Calculate new array.
            let sortedArray = (originalArray as NSArray).sortedArray(comparator: { (item1, item2) -> ComparisonResult in
                return comparator(item1 as! ModelType, item2 as! ModelType)
            }) as! [ModelType]
            sections.append(sortedArray)
            
            // Calculate ObjectChangeTuples.
            for (originalIndex, originalItem) in originalArray.enumerated() {
                let sortedIndex = sortedArray.index(of: originalItem)!
                if originalIndex != sortedIndex {
                    let from = IndexPath(item: originalIndex, section: sectionIndex)
                    let to = IndexPath(item: sortedIndex, section: sectionIndex)
                    objectChanges.append(.move(at: from, to: to))
                }
            }
        }
        
        dataSource.applyChanges(sections: sections, objectChanges: objectChanges, sectionChanges: [])
    }
}
