//
//  SnarlyNavController.swift
//  snarly
//
//  Created by Ghost on 10/6/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import UIKit

class SnarlyNavController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        
        var segue: UIStoryboardSegue? = super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
        
        if let id = identifier {
            
            if id == "idHideMenu" {
                segue = MenuSegueUnwind(identifier: id, source: fromViewController, destination: toViewController)
                return segue!
            }
            
        }
        else {
            
            if #available(iOS 9.0, *) {
                super.unwindForSegue(segue!, towardsViewController: toViewController)
            } else {
                segue = super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)!
            }
            
            
        }
        return segue!
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
