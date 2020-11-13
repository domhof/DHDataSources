import Foundation

public class TableViewUpdater: DataSourceChangeObserver {
    
    private weak var tableView: UITableView?
    
    public init(tableView: UITableView) {
        self.tableView = tableView
    }
    
    public func dataSourceDidChange(objectChanges: [ObjectChange], sectionChanges: [SectionChange]) {
        guard let tableView = tableView else { return }
        
        tableView.beginUpdates()
        
        // Apply object changes.
        for change in objectChanges {
            switch(change) {
            case let .insert(at: indexPath):
                tableView.insertRows(at: [indexPath], with: .automatic)
            case let .delete(at: indexPath):
                tableView.deleteRows(at: [indexPath], with: .automatic)
            case let .update(at: indexPath):
                tableView.reloadRows(at: [indexPath], with: .automatic)
            case let .move(at: at, to: to):
                tableView.deleteRows(at: [at], with: .automatic)
                tableView.insertRows(at: [to], with: .automatic)
            }
        }
        
        // Apply section changes.
        for change in sectionChanges {
            switch(change) {
            case let .insert(at: sectionIndex):
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
            case let .delete(at: sectionIndex):
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
            }
        }
        
        if sectionChanges.count > 0 {
            self.reloadAllItems()
        }
        
        tableView.endUpdates()
    }
    
    public func reloadAllItems() {
        tableView?.reloadData()
    }
}
