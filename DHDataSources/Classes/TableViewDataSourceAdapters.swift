import Foundation
import UIKit

public protocol TableViewDataSourceAdapterProtocol: UITableViewDataSource {
    
    func dataSourceForTableView(_ tableView: UITableView, atIndexPath indexPath: IndexPath) -> (dataSource: AnyObject, convertedIndexPath: IndexPath)
    
    /// Connects a model at an indexPath to a cell at a different indexPath within the tableView.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, indexPathInTableView: IndexPath) -> UITableViewCell
}

public class TableViewDataSourceAdapter<DataSourceType: DataSource, ModelType>: NSObject, TableViewDataSourceAdapterProtocol where DataSourceType.ModelType == ModelType {
    
    public typealias CellProvider = (_ tableView: UITableView, _ indexPath: IndexPath, _ model: ModelType) -> UITableViewCell
    public typealias SectionHeaderProvider = (_ tableView: UITableView, _ section: Int) -> String?
    
    public let dataSource: DataSourceType
    private let cellProvider: CellProvider
    private let sectionHeaderProvider: SectionHeaderProvider?
    
    public init(dataSource: DataSourceType, cellProvider: @escaping CellProvider, sectionHeaderProvider: SectionHeaderProvider? = nil) {
        self.dataSource = dataSource
        self.cellProvider = cellProvider
        self.sectionHeaderProvider = sectionHeaderProvider
        super.init()
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections()
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfItemsInSection(section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = dataSource[indexPath]
        
        return cellProvider(tableView, indexPath, model)
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaderProvider?(tableView, section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, indexPathInTableView: IndexPath) -> UITableViewCell {
        return cellProvider(tableView, indexPathInTableView, dataSource[indexPath])
    }
    
    public func dataSourceForTableView(_ tableView: UITableView, atIndexPath indexPath: IndexPath) -> (dataSource: AnyObject, convertedIndexPath: IndexPath) {
        return (dataSource: dataSource, convertedIndexPath: indexPath)
    }
}

public class CombinedTableViewDataSourceAdapter<TableViewDataSource: UITableViewDataSource>: NSObject, UITableViewDataSource {
    
    let tableViewDataSourceAdapters: [TableViewDataSource]
    
    public init(tableViewDataSourceAdapters: [TableViewDataSource]) {
        self.tableViewDataSourceAdapters = tableViewDataSourceAdapters
        super.init()
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewDataSourceAdapters.reduce(0) { (count, adapter) -> Int in
            return count + adapter.numberOfSections!(in: tableView)
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let (adapter, section) = findAdapterForSection(section, inTableView: tableView)
        return adapter.tableView(tableView, numberOfRowsInSection: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let (adapter, section) = findAdapterForSection(indexPath.section, inTableView: tableView)
        return adapter.tableView(tableView, cellForRowAt: IndexPath(item: indexPath.item, section: section))
    }
    
    private func findAdapterForSection(_ section: Int, inTableView tableView: UITableView) -> (adapter: UITableViewDataSource, section: Int) {
        var numberOfRemainingSections = section
        for adapter in tableViewDataSourceAdapters {
            let numberOfSectionsInAdapter = adapter.numberOfSections!(in: tableView)
            if numberOfRemainingSections < numberOfSectionsInAdapter {
                return (adapter: adapter, section: numberOfRemainingSections)
            } else {
                numberOfRemainingSections -= numberOfSectionsInAdapter
            }
        }
        fatalError("CombinedTableViewDataSourceAdapter inconsistency")
    }
}

open class FlattenedTableViewDataSourceAdapter: NSObject, TableViewDataSourceAdapterProtocol {
    
    let tableViewDataSourceAdapters: [TableViewDataSourceAdapterProtocol]
    
    public init(tableViewDataSourceAdapters: [TableViewDataSourceAdapterProtocol]) {
        self.tableViewDataSourceAdapters = tableViewDataSourceAdapters
        super.init()
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewDataSourceAdapters.reduce(0) { (itemsCount, adapter) -> Int in
            return itemsCount + (0 ... adapter.numberOfSections!(in: tableView) - 1).reduce(0) { (sectionCount, section) -> Int in
                return sectionCount + adapter.tableView(tableView, numberOfRowsInSection: section)
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            fatalError("Section must be 0")
        }
        
        let (adapter, indexPathInAdapter) = adapterForTableView(tableView, atIndexPath: indexPath)
        return adapter.tableView(tableView, cellForRowAt: indexPathInAdapter, indexPathInTableView: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, indexPathInTableView: IndexPath) -> UITableViewCell {
        guard indexPath.section == 0 else {
            fatalError("Section must be 0")
        }
        
        let (adapter, indexPath) = adapterForTableView(tableView, atIndexPath: indexPath)
        return adapter.tableView(tableView, cellForRowAt: indexPath, indexPathInTableView: indexPathInTableView)
    }
    
    private func adapterForTableView(_ tableView: UITableView, atIndexPath indexPath: IndexPath) -> (adapter: TableViewDataSourceAdapterProtocol, indexPath: IndexPath) {
        var numberOfRemainingItems = indexPath.item
        for adapter in tableViewDataSourceAdapters {
            for section in 0 ... adapter.numberOfSections!(in: tableView) {
                let numberOfItemsInSection = adapter.tableView(tableView, numberOfRowsInSection: section)
                if numberOfRemainingItems < numberOfItemsInSection {
                    return (adapter: adapter, indexPath: IndexPath(item: numberOfRemainingItems, section: section))
                } else {
                    numberOfRemainingItems -= numberOfItemsInSection
                }
            }
        }
        fatalError("FlattenedTableViewDataSourceAdapter inconsistency")
    }
    
    public func dataSourceForTableView(_ tableView: UITableView, atIndexPath indexPath: IndexPath) -> (dataSource: AnyObject, convertedIndexPath: IndexPath) {
        let (adapter, convertedIndexPath) = adapterForTableView(tableView, atIndexPath: indexPath)
        return adapter.dataSourceForTableView(tableView, atIndexPath: convertedIndexPath)
    }
}
