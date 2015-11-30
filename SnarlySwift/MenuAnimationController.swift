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
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView()
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toView = toViewController.view
        let fromView = fromViewController.view
        let direction: CGFloat = reverse ? 1 : -1
        
        let viewFromTransform: CGAffineTransform = CGAffineTransformMakeTranslation(-direction * containerView!.frame.size.width/3, 0.0)
        let viewToTransform: CGAffineTransform = CGAffineTransformMakeTranslation(direction * containerView!.frame.size.width, 0.0)
        
        containerView!.addSubview(toView)
        toView.transform = viewToTransform
        fromView.transform = CGAffineTransformMakeTranslation(0.0, 0.0)
        
        
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: {

            toView.transform = CGAffineTransformIdentity

            fromView.transform = viewFromTransform
            
            }, completion: {
                finished in
                containerView!.transform = CGAffineTransformIdentity
                fromView.transform = CGAffineTransformIdentity
                toView.transform = CGAffineTransformIdentity
                
                if (transitionContext.transitionWasCancelled()) {
                    toView.removeFromSuperview()
                } else {
                    fromView.removeFromSuperview()
                }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        })        
    }
    
}