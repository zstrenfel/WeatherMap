//
//  AdminToolsViewController.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/27/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import UIKit
import CoreData

class AdminToolsViewController: UIViewController {
    
    //MARK: - Properties
    @IBOutlet weak var deleteHistoryButton: UIButton!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions

    @IBAction func deleteHistory(_ sender: UIButton) {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "WeatherHistory")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            let _ = try context.execute(request)
        } catch {
            log.error("could not execute request \(error)")
        }
    }
    
    @IBAction func closeModal(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}
