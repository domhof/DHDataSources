import Foundation
import UIKit

public class TableViewDataSourceAdapter<DataSourceType: DataSource, ModelType>: NSObject, UITableViewDataSource where DataSourceType.ModelType == ModelType {
    
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
