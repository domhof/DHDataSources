import Foundation

class ObserverContainer {
    private var changeObservers = [(dataSourceChangeObserver: DataSourceChangeObserver, indexPathOffset: IndexPath, ignoreChangeTypes: [ChangeType])]()
    
    func add(observer: DataSourceChangeObserver, ignoreChangeTypes: [ChangeType], indexPathOffset: IndexPath, firstAdded: (() -> ())? = nil) {
        #warning("Use lock to prevent concurrent access.")
        
        changeObservers.append((observer, indexPathOffset, ignoreChangeTypes))
        
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
    
    func dataSourceDidChange(objectChanges: [ObjectChangeTuple], sectionChanges: [SectionChangeTuple]) {
        for (observer, indexPathOffset, ignoreChangeTypes) in changeObservers {
            if !ignoreChangeTypes.isEmpty {
                let filterdSectionChanges: [SectionChangeTuple]
                let filterdObjectChanges: [ObjectChangeTuple]
                if indexPathOffset == IndexPath(item: 0, section: 0) {
                    filterdObjectChanges = objectChanges.filter { !ignoreChangeTypes.contains($0.changeType) }
                    filterdSectionChanges = sectionChanges.filter { !ignoreChangeTypes.contains($0.changeType) }
                } else {
                    filterdObjectChanges = objectChanges.compactMap({ objectChangeTuple -> ObjectChangeTuple? in
                        if ignoreChangeTypes.contains(objectChangeTuple.changeType) {
                            return nil
                        } else {
                            let indexPaths = objectChangeTuple.indexPaths.map { IndexPath(item: $0.item + indexPathOffset.item, section: $0.section + indexPathOffset.section) }
                            return (objectChangeTuple.changeType, indexPaths)
                        }
                    })
                    filterdSectionChanges = sectionChanges.compactMap({ sectionChangeTuple -> SectionChangeTuple? in
                        if ignoreChangeTypes.contains(sectionChangeTuple.changeType) {
                            return nil
                        } else {
                            return (sectionChangeTuple.changeType, sectionChangeTuple.sectionIndex + indexPathOffset.section)
                        }
                    })
                }
                
                observer.dataSourceDidChange(objectChanges: filterdObjectChanges, sectionChanges: filterdSectionChanges)
            } else {
                observer.dataSourceDidChange(objectChanges: objectChanges, sectionChanges: sectionChanges)
            }
        }
    }
    
    public func reloadAllItems() {
        #warning("Use lock to prevent concurrent access.")
        
        changeObservers.forEach { $0.dataSourceChangeObserver.reloadAllItems() }
    }
}
