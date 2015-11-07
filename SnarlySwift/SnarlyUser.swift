//
//  SnarlyUser.swift
//  snarly
//
//  Created by Ghost on 10/10/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import Bolts
import Foundation
import Parse
import ParseFacebookUtilsV4
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit


class SnarlyUser {
    static let sharedInstance = SnarlyUser()
    var isFacebookLinked: Bool!

    func loginWithFacebook() {
        let permissions: NSArray = [ "public_profile", "user_friends", "user_location", "email" ]
        
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions as? [String]) {
            (user: PFUser?, error: NSError?) -> Void in
            
            print(user, error)
            
            if let user = user {
                
                if user.isNew {
                    
                    SnarlySpotSync().syncUserSpots()
                    
                } else {
                    
                    let request: FBSDKGraphRequest = FBSDKGraphRequest.init(graphPath: "me?fields=id,name,location,first_name,last_name,email", parameters: nil)
                    request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
                        
                        if error == nil {
                            
                            let userData:NSDictionary = result as! NSDictionary
                            
                            let facebookID = userData.valueForKey("id") as! String
                            let location = userData.valueForKey("location")
                            var userLocation = location?.valueForKey("name")
                            let first_name = userData.valueForKey("first_name") as! String
                            let last_name = userData.valueForKey("last_name") as! String
                            
                            if userLocation == nil {
                                userLocation = ""
                            }
                            
                            let pictureURL: NSURL = NSURL(string: "https://graph.facebook.com/\(facebookID)/picture?type=large")!
                        
                            
                            let urlRequest: NSURLRequest = NSURLRequest(URL: pictureURL)
                            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, connectionError) -> Void in
                                
                                if(connectionError == nil && data != nil) {
                                    
                                    user["first_name"] = first_name
                                    user["last_name"] = last_name
                                    user["location"] = userLocation
                                    user["email"] = userData.valueForKey("email")
                                    
                                    let file = PFFile(name: "\(first_name)\(last_name).jpg", data: data!)
                                    
                                    file.saveInBackgroundWithBlock { (succeeded: Bool, let error: NSError?) -> Void in
                                        
                                        if succeeded {
                                            
                                            user["photo"] = file
                                            NSNotificationCenter.defaultCenter().postNotificationName("loggedInWithFacebook", object: nil)
            
                                        }
                                        
                                        user.saveEventually()
                                        
                                    }

                                    
                                } else {
                                    print("picture url \(pictureURL)")
                                }
                                
                            })
                            
                            
                            
                        } else {
                            NSNotificationCenter.defaultCenter().postNotificationName("loggedOut", object: nil)
                            print("error url \(error)")
                            
                        }
                        
                    }
                    
                }
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("loggedOut", object: nil)
                print("user \(user)")
                
            }
        }
        
    }
    
    func inviteDialog(sender: UIViewController!) {
        let dialog:FBSDKAppInviteDialog = FBSDKAppInviteDialog()
        
        if(dialog.canShow()){
            
            let content: FBSDKAppInviteContent = FBSDKAppInviteContent()
            
            content.appLinkURL = NSURL(string: "https://fb.me/1029625583756110")
            content.appInvitePreviewImageURL = NSURL(string: "http://getsnarly.com/images/fb_icon.png")
            
            dialog.content = content
            dialog.fromViewController = sender
            print(dialog)
            
            dialog.show()
            do {
                try dialog.validate()
            } catch {
                print(error)
            }
            
            
        } else {
            print("cannot show dialog")
        }
    }
    
    func isFBLoggedIn() -> Bool {
        
        if (PFUser.currentUser() != nil) {
        
            isFacebookLinked = (PFUser.currentUser()?.isLinkedWithAuthType("facebook"))!
            
        } else {
            
            isFacebookLinked = false
            
        }
        
        return isFacebookLinked
        
    }
    
    
}