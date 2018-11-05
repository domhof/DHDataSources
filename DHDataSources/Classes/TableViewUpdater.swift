import Foundation

public class TableViewUpdater: DataSourceChangeObserver {
    
    private let tableView: UITableView
    
    public init(tableView: UITableView) {
        self.tableView = tableView
    }
    
    public func dataSourceDidChange(objectChanges: [ObjectChangeTuple], sectionChanges: [SectionChangeTuple]) {
        tableView.beginUpdates()
        
        // Apply object changes.
        for (changeType, indexPaths) in objectChanges {
            switch(changeType) {
            case .insert:
                tableView.insertRows(at: indexPaths, with: .automatic)
            case .delete:
                tableView.deleteRows(at: indexPaths, with: .automatic)
            case .update:
                tableView.reloadRows(at: indexPaths, with: .automatic)
            case .move:
                if let deleteIndexPath = indexPaths.first {
                    tableView.deleteRows(at: [deleteIndexPath], with: .automatic)
                }
                
                if let insertIndexPath = indexPaths.last {
                    tableView.insertRows(at: [insertIndexPath], with: .automatic)
                }
            }
        }
        
        // Apply section changes.
        for (changeType, sectionIndex) in sectionChanges {
            let section = IndexSet(integer: sectionIndex)
            
            switch(changeType) {
            case .insert:
                tableView.insertSections(section, with: .automatic)
            case .delete:
                tableView.deleteSections(section, with: .automatic)
            default:
                break
            }
        }
        
        if sectionChanges.count > 0 {
            self.reloadAllItems()
        }
        
        tableView.endUpdates()
    }
    
    public func reloadAllItems() {
        tableView.reloadData()
    }
}
