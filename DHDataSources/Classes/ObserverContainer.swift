import Foundation

class ObserverContainer {
    struct ChangeObserver {
        let dataSourceChangeObserver: DataSourceChangeObserver
        let indexPathOffset: IndexPath
        let ignoreObjectChangeTypes: [ObjectChange.ChangeType]
        let ignoreSectionChangeTypes: [SectionChange.ChangeType]
    }
    private var changeObservers = [ChangeObserver]()
    
    func add(observer: DataSourceChangeObserver, ignoreObjectChangeTypes: [ObjectChange.ChangeType], ignoreSectionChangeTypes: [SectionChange.ChangeType], indexPathOffset: IndexPath, firstAdded: (() -> ())? = nil) {
        #warning("Use lock to prevent concurrent access.")
        
        changeObservers.append(ChangeObserver(dataSourceChangeObserver: observer,
                                              indexPathOffset: indexPathOffset,
                                              ignoreObjectChangeTypes: ignoreObjectChangeTypes,
                                              ignoreSectionChangeTypes: ignoreSectionChangeTypes))
        
        if (changeObservers.count == 1) {
            firstAdded?()
        }
    }
    
    func remove(observer: DataSourceChangeObserver, lastRemoved: (() -> ())? = nil) {
        #warning("Use lock to prevent concurrent access.")
        
        guard let i = changeObservers.firstIndex(where: { $0.dataSourceChangeObserver === observer }) else { return }
        
        changeObservers.remove(at: i)
        if changeObservers.isEmpty {
            lastRemoved?()
        }
    }
    
    func dataSourceDidChange(objectChanges: [ObjectChange], sectionChanges: [SectionChange]) {
        for changeObserver in changeObservers {
            let objectChanges = prepareObjectChanges(objectChanges, for: changeObserver)
            let sectionChanges = prepareSectionChanges(sectionChanges, for: changeObserver)
            changeObserver.dataSourceChangeObserver.dataSourceDidChange(objectChanges: objectChanges, sectionChanges: sectionChanges)
        }
    }
    
    private func prepareObjectChanges(_ changes: [ObjectChange], for changeObserver: ChangeObserver) -> [ObjectChange] {
        var changes = changes
        if !changeObserver.ignoreObjectChangeTypes.isEmpty {
            if changeObserver.indexPathOffset == IndexPath(item: 0, section: 0) {
                changes = changes.filter { !changeObserver.ignoreObjectChangeTypes.contains($0.type) }
            } else {
                changes = changes.compactMap({
                    if changeObserver.ignoreObjectChangeTypes.contains($0.type) {
                        return nil
                    } else {
                        return $0.adding(offset: changeObserver.indexPathOffset)
                    }
                })
            }
        }
        return changes
    }
    
    private func prepareSectionChanges(_ changes: [SectionChange], for changeObserver: ChangeObserver) -> [SectionChange] {
        var changes = changes
        if !changeObserver.ignoreSectionChangeTypes.isEmpty {
            if changeObserver.indexPathOffset == IndexPath(item: 0, section: 0) {
                changes = changes.filter { !changeObserver.ignoreSectionChangeTypes.contains($0.type) }
            } else {
                changes = changes.compactMap({
                    if changeObserver.ignoreSectionChangeTypes.contains($0.type) {
                        return nil
                    } else {
                        return $0.adding(offset: changeObserver.indexPathOffset.section)
                    }
                })
            }
        }
        return changes
    }
    
    public func reloadAllItems() {
        #warning("Use lock to prevent concurrent access.")
        
        changeObservers.forEach { $0.dataSourceChangeObserver.reloadAllItems() }
    }
}
