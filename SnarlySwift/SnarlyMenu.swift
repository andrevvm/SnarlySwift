//
//  SnarlyMenu.swift
//  snarly
//
//  Created by Ghost on 9/25/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import Foundation

class SnarlyMenu: UIViewController {
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {

        self.navigationController?.navigationBar.backgroundColor = UIColor(red: 0.9414, green: 0.2187, blue: 0.2734, alpha: 1.0)
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

}