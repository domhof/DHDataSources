import Foundation

public class CombinedDataSource<DataSource1Type: DataSource, DataSource2Type: DataSource, ModelType>: NSObject, DataSource where ModelType == DataSource1Type.ModelType, DataSource1Type.ModelType == DataSource2Type.ModelType {
    
    private let dataSource1: DataSource1Type
    private let dataSource2: DataSource2Type
    
    public init(dataSource1: DataSource1Type, dataSource2: DataSource2Type) {
        self.dataSource1 = dataSource1
        self.dataSource2 = dataSource2
    }
    
    public func numberOfSections() -> Int {
        return dataSource1.numberOfSections() + dataSource2.numberOfSections()
    }
    
    public func numberOfItemsInSection(_ section: Int) -> Int {
        let numberOfSectionsInDS1 = dataSource1.numberOfSections()
        if section < numberOfSectionsInDS1 {
            return dataSource1.numberOfItemsInSection(section)
        } else {
            return dataSource2.numberOfItemsInSection(section - numberOfSectionsInDS1)
        }
    }
    
    public func totalNumberOfItems() -> Int {
        return dataSource1.totalNumberOfItems() + dataSource2.totalNumberOfItems()
    }
    
    public subscript(indexPath: IndexPath) -> ModelType {
        get {
            let numberOfSectionsInDS1 = dataSource1.numberOfSections()
            if indexPath.section < numberOfSectionsInDS1 {
                return dataSource1[indexPath]
            } else {
                let indexPath = IndexPath(item: indexPath.item, section: indexPath.section - numberOfSectionsInDS1)
                return dataSource2[indexPath]
            }
        }
    }
    
    public func subscribe(observer: DataSourceChangeObserver, ignoreChangeTypes: [ChangeType], indexPathOffset: IndexPath) {
        fatalError("not implemented")
    }
    
    public func unsubscribe(observer: DataSourceChangeObserver) {
        fatalError("not implemented")
    }
}
