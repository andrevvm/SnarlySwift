//
//  MenuSegueUnwind.swift
//  snarly
//
//  Created by Ghost on 10/6/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import UIKit

class MenuSegueUnwind: UIStoryboardSegue {
    override func perform() {
        // Assign the source and destination views to local variables.
        let secondVCView = self.sourceViewController.view as UIView!
        let firstVCView = self.destinationViewController.view as UIView!
        
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(firstVCView, aboveSubview: secondVCView)
        
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            secondVCView.frame = CGRectOffset(secondVCView.frame, -screenWidth, 0.0)
            }) { (Finished) -> Void in
                
        }
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            firstVCView.frame = CGRectOffset(firstVCView.frame, -(screenWidth), 0.0)
            }) { (Finished) -> Void in
                
                self.sourceViewController.dismissViewControllerAnimated(false, completion: nil)
                
        }
        
    }
}
