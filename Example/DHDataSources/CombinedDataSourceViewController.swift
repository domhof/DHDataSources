import UIKit
import DHDataSources

struct ModelA {
    let identifier: String
}

struct ModelB {
    let identifier: String
}

class CombinedDataSourceViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var tableViewDataSource: UITableViewDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let modelADataSource = createModelADataSource1()
        let modelBDataSource = createModelADataSource2()
        
        // dataSource1 will be section 0
        // dataSource2 will be section 1
        let dataSource = CombinedDataSource(dataSource1: modelADataSource,
                                            dataSource2: modelBDataSource)
        
        let cellReuseIdentifier = "cell"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        let cellProvider = { (tableView: UITableView, indexPath: IndexPath, model: ModelA) -> UITableViewCell in
            let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
            cell.textLabel!.text = model.identifier
            return cell
        }
        
        let sectionHeaderProvider = { (tableView: UITableView, section: Int) -> String? in
            return "Section \(section)"
        }
        
        tableViewDataSource = TableViewDataSourceAdapter(dataSource: dataSource,
                                                         cellProvider: cellProvider,
                                                         sectionHeaderProvider: sectionHeaderProvider)
        
        tableView.dataSource = tableViewDataSource
    }
    
    private func createModelADataSource1() -> ArrayDataSource<ModelA> {
        let models = [ModelA(identifier: "modelA1.1"),
                      ModelA(identifier: "modelA1.2"),
                      ModelA(identifier: "modelA1.3")]
        let dataSource = ArrayDataSource(items: models)
        
        return dataSource
    }
    
    private func createModelADataSource2() -> ArrayDataSource<ModelA> {
        let models = [ModelA(identifier: "modelA2.1"),
                      ModelA(identifier: "modelA2.2"),
                      ModelA(identifier: "modelA2.3")]
        let dataSource = ArrayDataSource(items: models)
        
        return dataSource
    }
}

