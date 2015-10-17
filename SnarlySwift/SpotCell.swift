//
//  SpotCell.swift
//  SnarlySwift
//
//  Created by Ghost on 8/5/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import UIKit
import ParseUI

let ImageHeight: CGFloat = 330.0
let OffsetSpeed: CGFloat = 20.0

class SpotCell: PFTableViewCell {
    @IBOutlet var spotLabel: UILabel!
    @IBOutlet var spotPhoto: UIImageView!
    @IBOutlet var spotMask: UIView!
    @IBOutlet var sampleOverlay: UIImageView!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
        
    
//    func offset(offset: CGPoint) {
//        spotPhoto!.frame = CGRectOffset(self.imageView!.bounds, offset.x, offset.y)
//    }
    

}
