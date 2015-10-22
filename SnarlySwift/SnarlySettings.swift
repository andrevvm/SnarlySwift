//
//  SnarlySettings.swift
//  snarly
//
//  Created by Ghost on 10/8/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4
import FBSDKShareKit

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
}

class SnarlySettings: ViewController {
    
    @IBOutlet var userSettings: UIView!
    @IBOutlet var profilePic: UIImageView!
    @IBOutlet var profileName: UILabel!
    
    let snarlyUser = SnarlyUser()
    
    var isLoggedIn:Bool = false
    var isFacebookLinked:Bool = false
    
    @IBAction func facebookConnect() {
        
        snarlyUser.loginWithFacebook()
        userSettings.hidden = false
        profilePic.image = nil
        
    }
    
    @IBAction func inviteUsers() {
        
        snarlyUser.inviteDialog(self)
        
    }
    
    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        print("Complete invite without error")
    }
    
    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: NSError!) {
        print("Error in invite \(error)")
    }
    
    @IBAction func logOut() {
        
        userSettings.hidden = true
        
        PFUser.logOutInBackgroundWithBlock { (error: NSError?) -> Void in
            
            if (error != nil) {
                
                self.userSettings.hidden = false
                let logOutAlert:UIAlertView = UIAlertView(title: "Unable to logout", message: "Check your internet connection and try again", delegate: self, cancelButtonTitle: "OK")
                logOutAlert.show()
                
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("loggedOut", object: nil)
            }
            
            
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        profilePic.layer.cornerRadius = 50
        profilePic.clipsToBounds = true
        
        if (PFUser.currentUser() != nil) {
            
            isLoggedIn = (PFUser.currentUser()?.isAuthenticated())!
            isFacebookLinked = (PFUser.currentUser()?.isLinkedWithAuthType("facebook"))!
            
        }
            
        if (isLoggedIn == true || isFacebookLinked == true ) {
            
            loadUserView()
            
            
        }  else {
            userSettings.hidden = true
        }

    }
    
    @IBAction func loadUserView() {
        
        userSettings.hidden = false
        
        isLoggedIn = (PFUser.currentUser()?.isAuthenticated())!
        isFacebookLinked = (PFUser.currentUser()?.isLinkedWithAuthType("facebook"))!
        
        if (isFacebookLinked) {
            
            NSNotificationCenter.defaultCenter().postNotificationName("loggedInWithFacebook", object: nil)
            
        }
        
        
    }
    
    func displayUserData() {
        
    }
    
    func userLoggedIn(sender: NSNotification) {
        
        let user = PFUser.currentUser()
        
        var nameString = ""
        
        if let lastName = user!["last_name"] as? String {
            let firstName = user!["first_name"]
            let lastNameString = lastName as String
            let lastLetter = lastNameString[0]
            nameString = "\(firstName as! String) \(lastLetter)."
        }
        profileName.text = nameString
        
        if(user?["photo"] != nil) {
            let photo:PFFile = ((user?["photo"]) as? PFFile)!
            let imageData:NSData?
            do {
                try imageData = photo.getData()
                
                profilePic.image = UIImage(data: imageData!)
            } catch {
                print("no photo")
            }
        } else {
            print("no photo")
        }
        
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("userLoggedIn:"), name:"loggedInWithFacebook", object: nil);
    
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
//        if let id = segue.identifier {
//            switch id {
//                
//            case "unwindToSaved":
//                SpotList().type = "saved"
//            case "unwindToFriends":
//                SpotList().type = "friends"
//            default:
//                SpotList().type = "saved"
//                
//            }
//        }
        
        
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
