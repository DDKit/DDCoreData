//
//  DDCoreData.swift
//  DDCoreData
//
//  Created by 风荷举 on 2018/12/8.
//  Copyright © 2018年 ddWorker. All rights reserved.
//

import UIKit
import CoreData

public class DDCoreData: NSObject {
    
    private var name: String!
    
    public init(_ name: String) {
        self.name = name
    }
    
    private var result: NSFetchedResultsController<NSFetchRequestResult>?
    
    public var resultWillChange: ((_ controller :NSFetchedResultsController<NSFetchRequestResult>)->Void)?
    
    public var resultDidChanged: ((_ controller :NSFetchedResultsController<NSFetchRequestResult>)->Void)?

    public var sectionDidChanged: ((_ controller :NSFetchedResultsController<NSFetchRequestResult>,_ type: NSFetchedResultsChangeType ,_ sectionIndex: Int)->Void)?
    
    public var rowDidChanged: ((_ controller :NSFetchedResultsController<NSFetchRequestResult>,_ type: NSFetchedResultsChangeType ,_ anObject: Any,_ atIndex: IndexPath?,_ newIndex: IndexPath?)->Void)?

    public var resultSectionName: ((_ controller :NSFetchedResultsController<NSFetchRequestResult>, _ sectionName: String)->String)?
    
    
    private lazy var model: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: name, withExtension: "momd")!
        let m = NSManagedObjectModel(contentsOf: modelURL)
        return m!
    }()
    
    private lazy var coordinator: NSPersistentStoreCoordinator = {
        let coor = NSPersistentStoreCoordinator(managedObjectModel: model)
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let url = directory.appendingPathComponent("\(name!).sqlite")
        let store = try? coor.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        if store == nil {
            print("数据建库失败")
        }
        return coor
    }()
    
    public lazy var context: NSManagedObjectContext = {
        let con = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        con.persistentStoreCoordinator = coordinator
        return con
    }()
    
    public func save() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
    public func results<T>(_ request:NSFetchRequest<T>,_ sectionName: String? = nil) -> NSFetchedResultsController<T> where T:NSFetchRequestResult {
        if result == nil {
            result = (NSFetchedResultsController(fetchRequest: request,
                                                 managedObjectContext:context,
                                                 sectionNameKeyPath: sectionName,
                                                 cacheName: nil) as! NSFetchedResultsController<NSFetchRequestResult>)
            result!.delegate = self
            do {
                try result!.performFetch()
            } catch {
                print("\(error)")
            }
        }
        return (result as! NSFetchedResultsController<T>)
    }

    public func request<T>() -> NSFetchRequest<T> where T : NSManagedObject {
        return NSFetchRequest<T>(entityName: "\(T.self)")
    }
    
    public func search<T>(_ request: NSFetchRequest<T>) -> [T] where T : NSManagedObject {
        return (try? context.fetch(request)) ?? []
    }
    
    // 实例化一个需要添加的 实体 赋值后记得保存
    // 拿到检索后的实体 修改后记得保存
    public func insertModel<T>() -> T where T : NSManagedObject {
        return NSEntityDescription.insertNewObject(forEntityName: "\(T.self)", into: context) as! T
    }

    // 拿到检索的结果后做删除处理
    public func delete(_ model:NSManagedObject){
        context.delete(model)
        save()
    }
    
    // 拿到了检索的结构后批量删除处理
    public func delete(_ models:[NSManagedObject]){
        _ = models.map { (model) in
            context.delete(model)
        }
        save()
    }
    
}

extension DDCoreData: NSFetchedResultsControllerDelegate {
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        resultWillChange?(controller)
    }
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        resultDidChanged?(controller)
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return resultSectionName?(controller,sectionName) ?? sectionName
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        rowDidChanged?(controller,type,anObject,indexPath,newIndexPath)
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        sectionDidChanged?(controller,type,sectionIndex)
    }
}
