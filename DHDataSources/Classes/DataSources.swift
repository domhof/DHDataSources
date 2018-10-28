import Foundation

protocol DataSourceSorter {
    func sort()
}

//public class ArrayDataSourceSorter<ModelType: Equatable>: DataSourceSorter {
//    
//    let view: UpdateableView
//    let dataSource: ArrayDataSource<ModelType>
//    let comparator: (_ item1: ModelType, _ item1: ModelType) -> ComparisonResult
//    
//    public init(view: UpdateableView, dataSource: ArrayDataSource<ModelType>, comparator: @escaping (_ item1: ModelType, _ item2: ModelType) -> ComparisonResult) {
//        self.view = view
//        self.dataSource = dataSource
//        self.comparator = comparator
//    }
//    
//    public func sort() {
//        var objectChanges = [ObjectChangeTuple]()
//        dataSource.sections.enumerated().forEach { (index, originalArray) in
//            let sortedArray = (originalArray as NSArray).sortedArray(comparator: { (item1, item2) -> ComparisonResult in
//                return comparator(item1 as! ModelType, item2 as! ModelType)
//            }) as! [ModelType]
//            dataSource.sections[index] = sortedArray
//            
//            for (originalIndex, originalItem) in originalArray.enumerated() {
//                let sortedIndex = sortedArray.index(of: originalItem)!
//                if originalIndex != sortedIndex {
//                    let from = IndexPath(item: originalIndex, section: 0)
//                    let to = IndexPath(item: sortedIndex, section: 0)
//                    objectChanges.append(ObjectChangeTuple(changeType: .move, indexPaths:[from, to]))
//                }
//            }
//        }
//        view.applyChanges(objectChanges: objectChanges, sectionChanges: [])
//    }
//}
