//
//  SnarlyMenu.swift
//  snarly
//
//  Created by Ghost on 9/25/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import UIKit

class SnarlyMenu: ViewController {
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let image = UIImage(named: "snarly-logo-sm")
        self.navigationItem.titleView = UIImageView(image: image)
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
