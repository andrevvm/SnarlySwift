//
//  MenuAnimationController.swift
//  snarly
//
//  Created by Ghost on 10/19/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import Foundation
import UIKit

class MenuAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    var reverse: Bool = false
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.25
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView()
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toView = toViewController.view
        let fromView = fromViewController.view
        let direction: CGFloat = reverse ? 1 : -1
        
        let viewFromTransform: CATransform3D = CATransform3DMakeTranslation(-direction * containerView!.frame.size.width/3, 0.0, 0.0)
        let viewToTransform: CATransform3D = CATransform3DMakeTranslation(direction * containerView!.frame.size.width, 0.0, 0.0)
        
        toView.layer.transform = viewToTransform
        containerView!.addSubview(toView)
        
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {

            fromView.layer.transform = viewFromTransform
            toView.layer.transform = CATransform3DIdentity
            }, completion: {
                finished in
                containerView!.transform = CGAffineTransformIdentity
                fromView.layer.transform = CATransform3DIdentity
                toView.layer.transform = CATransform3DIdentity
                
                if (transitionContext.transitionWasCancelled()) {
                    toView.removeFromSuperview()
                } else {
                    fromView.removeFromSuperview()
                }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })        
    }
    
}