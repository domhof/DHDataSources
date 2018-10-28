import UIKit
import DHDataSources
import Photos

class PHFetchResultViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var tableViewDataSource: UITableViewDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    let fetchOptions = PHFetchOptions()
                    let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                    let dataSource = PHFetchResultDataSource(fetchResult: allPhotos)
                    
                    let cellReuseIdentifier = "cell"
                    self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
                    
                    let cellProvider = { (tableView: UITableView, indexPath: IndexPath, model: PHAsset) -> UITableViewCell in
                        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
                        cell.imageView?.contentMode = .scaleAspectFill
                        
                        let options = PHImageRequestOptions()
                        options.isSynchronous = true
                        options.version = .original
                        PHImageManager.default().requestImage(for: model, targetSize: CGSize(width: 40, height: 40), contentMode: .aspectFill, options: options) { image, _ in
                            guard let image = image else { return }
                            cell.imageView?.image = image
                        }
                        
                        return cell
                    }
                    
                    let sectionHeaderProvider = { (tableView: UITableView, section: Int) -> String? in
                        return nil
                    }
                    
                    self.tableViewDataSource = TableViewDataSourceAdapter(dataSource: dataSource,
                                                                          cellProvider: cellProvider,
                                                                          sectionHeaderProvider: sectionHeaderProvider)
                    
                    self.tableView.dataSource = self.tableViewDataSource
                    
                    let tableViewUpdater = TableViewUpdater(tableView: self.tableView)
                    dataSource.subscribe(observer: tableViewUpdater)
                }
                
            case .denied, .restricted:
                print("Not allowed")
            case .notDetermined:
                print("Not determined yet")
            }
        }
    }
}

