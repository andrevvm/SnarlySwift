//
//  SpotDetailController.swift
//  SnarlySwift
//
//  Created by Ghost on 8/6/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import UIKit

class SpotDetailController: UIViewController {
    var spot: Spots? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationController.navigationBar.topItem.title = ""
        if spot != nil {
            self.title = spot?.title
        }
    }
    
    
}
