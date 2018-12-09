//
//  ViewController.swift
//  DDCoreData
//
//  Created by duanchanghe@gmail.com on 12/09/2018.
//  Copyright (c) 2018 duanchanghe@gmail.com. All rights reserved.
//

import UIKit
import CoreData
import DDCoreData

class ViewController: UIViewController {
    
    let myData = DDCoreData("DDModelData")
    
    lazy var dataResult: NSFetchedResultsController<Person> = {
        let request = NSFetchRequest<Person>(entityName: "\(Person.self)")
        request.sortDescriptors = [NSSortDescriptor(key: "age", ascending: false)]
        return myData.results(request)
    }()
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func clickAction(_ sender: UIButton) {
        // 增
        let p: Person=myData.insertModel()
        p.name = "hahah"
        p.age = 5
        myData.save()
        
        let request: NSFetchRequest<Person> = myData.request()
        print(myData.search(request))
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myData.resultWillChange = { [weak self] (_) in
            self!.tableView.beginUpdates()
        }
        
        myData.resultDidChanged = { [weak self] (_) in
            self!.tableView.endUpdates()
        }
        
        myData.sectionDidChanged = { [weak self] (_,t,oi) in
            switch t {
            case .insert:
                self?.tableView.insertSections(IndexSet(integer: oi), with: .automatic)
                break
            case .delete:
                self?.tableView.deleteSections(IndexSet(integer: oi), with: .automatic)
                break
            case .update:
                break
            case .move:
                break
            }
        }
        myData.rowDidChanged = { [weak self] (_,t,o,oi,ni) in
            switch t {
            case .delete:
                self?.tableView.deleteRows(at: [oi!], with: .automatic)
                break
            case .insert:
                self?.tableView.insertRows(at: [ni!], with: .automatic)
                break
            case .move:
                self?.tableView.deleteRows(at: [oi!], with: .automatic)
                self?.tableView.insertRows(at: [ni!], with: .automatic)
                break
            case .update:
                self?.tableView.reloadRows(at: [oi!], with: .middle)
                break
            }
        }
    }
}

extension ViewController :UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataResult.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataResult.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let p: Person = dataResult.object(at: indexPath)
        cell.textLabel?.text = p.name
        cell.detailTextLabel?.text = "\(p.age)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 改
        let p: Person = dataResult.object(at: indexPath)
        p.age += 1
        myData.save()
    }
    
    // 删
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            let p: Person = dataResult.object(at: indexPath)
            myData.delete(p)
            break
        default:
            break
        }
    }
}

