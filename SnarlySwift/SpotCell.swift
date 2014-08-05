//
//  SpotCell.swift
//  SnarlySwift
//
//  Created by Ghost on 8/5/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import UIKit

class SpotCell: UITableViewCell {
    @IBOutlet var spotLabel: UILabel!
    @IBOutlet var spotPhoto: UIImageView!
    
    init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

}
