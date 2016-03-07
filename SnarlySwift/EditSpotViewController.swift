//
//  EditSpotViewController.swift
//  SnarlySwift
//
//  Created by Ghost on 8/4/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import UIKit
import MobileCoreServices
import CoreData
import CoreLocation
import AssetsLibrary
import ImageIO
import Parse

class CompressedImage: UIImageView {
    var compressedImageData: NSData?
    func CompressedJpeg(image: UIImage?, compressionTimes: Int){
        if var imageCompressed = image {
            for (var i = 0 ; i<compressionTimes; i++) {
                compressedImageData = UIImageJPEGRepresentation(imageCompressed, 0.0)
                imageCompressed = UIImage(data: compressedImageData!)!
            }
            self.image = imageCompressed
        }else{
            compressedImageData = nil
            self.image = nil
        }
    }
}

class EditSpotViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate, UITextFieldDelegate {
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var spot: Spots? = nil
    var newSpot: Spots? = nil
    var capturedImage: UIImage?

    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var txtSpotName: UITextField!
    @IBOutlet var txtSpotNotes: UITextField!
    @IBOutlet var switchBust: UISwitch!
    @IBOutlet var switchPrivate: UISwitch!
    @IBOutlet var imagePreview : CompressedImage!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var editView: UIView!
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var bottomGuide: UILabel!
    @IBOutlet var privacyControl: UISegmentedControl!
    @IBOutlet var loadingView: UIView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var tempImage: UIImage!
    
    var location: CLLocation!
    var locationString: String!
    
    var keyboard = false
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        
        txtSpotName.attributedPlaceholder = NSAttributedString(string:"Spot name",
            attributes:[NSForegroundColorAttributeName: UIColor(red: 0.658, green: 0.607, blue: 0.611, alpha: 1.0)])
        
        txtSpotNotes.attributedPlaceholder = NSAttributedString(string:"Notes",
            attributes:[NSForegroundColorAttributeName: UIColor(red: 0.658, green: 0.607, blue: 0.611, alpha: 1.0)])
        
        if(newSpot != nil) {
            tempImage = UIImage(data: newSpot?.photo as NSData!)
            imagePreview.image = tempImage
        }
        
        if(spot != nil) {
            txtSpotName.text = spot!.title
            txtSpotNotes.text = spot!.notes
            imagePreview.image = UIImage(data: spot?.photo as NSData!)
            if spot!.bust {
                switchBust.on = true
            } else {
                switchBust.on = false
            }
            if spot!.isPrivate {
                switchPrivate.on = true
            } else {
                switchPrivate.on = false
            }

            navigationBar.topItem!.title = "Edit Spot"
            
        } else {
            navigationBar.topItem!.title = "New Spot"
        }

        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(Bool())
        
        self.navigationController?.navigationBarHidden = false
        
        saveButton.enabled = true
    }
    
    
    @IBAction func saveSpot(sender: UIBarButtonItem) {
        
        saveButton.enabled = false
        loadingView.hidden = false
        
        if(newSpot != nil) {
            
            let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
            let spot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
            
            let imageData = NSData(data: UIImageJPEGRepresentation(imagePreview.image!, 0.6)!)
            
            spot.title = txtSpotName.text
            spot.notes = txtSpotNotes.text!
            spot.photo = imageData
            let location = CLLocation(latitude: newSpot!.loc_lat as Double, longitude: newSpot!.loc_lon as Double)
            if appDelegate.location != nil {
                let distance = appDelegate.location!.distanceFromLocation(location) as CLLocationDistance
                let distanceNum:Double = distance
                spot.distance = distanceNum
            } else {
                spot.distance = 0
            }
            
            spot.loc_disp = newSpot!.loc_disp
            spot.loc_lat = newSpot!.loc_lat
            spot.loc_lon = newSpot!.loc_lon
            spot.active = true
            
            if switchBust.on {
                spot.bust = true
            } else {
                spot.bust = false
            }
            
            if switchPrivate.on {
                spot.isPrivate = true
            } else {
                spot.isPrivate = false
            }
            
            if SnarlyUser().isFBLoggedIn() {
                spot.userid = PFUser.currentUser()?.objectId
            }
            
            if spot.loc_disp == "" && Reachability.connectedToNetwork() {
                appDelegate.getLocationString(spot.loc_lat as Double, loc_lon: spot.loc_lon as Double, completion: { (answer) -> Void in
                    spot.loc_disp = answer
                    
                    self.finishSavingSpot(spot)
                })
            } else {
                self.finishSavingSpot(spot)
            }
            
        } else {
            
            let imageData = NSData(data: UIImageJPEGRepresentation(imagePreview.image!, 1)!)
            
            spot!.title = txtSpotName.text
            spot!.notes = txtSpotNotes.text!
            spot!.photo = imageData
            
            if switchBust.on {
                spot!.bust = true
            } else {
                spot!.bust = false
            }
            if switchPrivate.on {
                spot!.isPrivate = true
            } else {
                spot!.isPrivate = false
            }
            
            do {
                try self.managedObjectContext?.save()
                if spot!.uuid != nil {
                    SnarlySpotSync().update(spot!, objectID: spot!.uuid!)
                }
                
            } catch _ {
            }
            performSegueWithIdentifier("editSpot", sender: spot!)
            
        }
        
        
        
    }
    
    func finishSavingSpot(spot: Spots) {
        do {
            try managedObjectContext?.save()
            SnarlySpotSync().save(spot)
        } catch _ {
        }
        self.saveButton.enabled = true
        self.loadingView.hidden = true
        performSegueWithIdentifier("newSpot", sender: self)
    }
    

    
    func RBResizeImage(image: UIImage) -> UIImage {
        let size = image.size
        
        let targetSize = CGSizeMake(968, 1296)
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
        } else {
            newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRectMake(0, 0, newSize.width, newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func keyboardWillShow(sender: NSNotification) {
        
        keyboard = true
        
        let info = sender.userInfo!
        
        let frame = -(info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        let offset = screenHeight - editView.frame.size.height - 210
        
        self.topConstraint.constant = frame + offset
        UIView.animateWithDuration(0.3) {
            self.view.layoutIfNeeded()
        }
        
        
    }
    
    func keyboardWillHide(sender: NSNotification) {
        
        keyboard = false
        
        self.topConstraint.constant = 0
        UIView.animateWithDuration(0.3) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == txtSpotName { // Switch focus to other text field
            txtSpotNotes.becomeFirstResponder()
        }
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func capture(sender : AnyObject) {
        
        if keyboard {
            view.endEditing(true)
            return
        }
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
            
            let imag = UIImagePickerController()
            imag.delegate = self
            imag.sourceType = UIImagePickerControllerSourceType.Camera;
            imag.mediaTypes = [kUTTypeImage as String]
            imag.allowsEditing = false
            
            self.presentViewController(imag, animated: true, completion: nil)
        }
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        tempImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let resizedImage = RBResizeImage(tempImage)
        
        imagePreview.image=resizedImage
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        segue.sourceViewController.view.endEditing(true)
        
        if segue.identifier == "exit" {
            return
        }
        
        if segue.destinationViewController.isMemberOfClass(SpotDetailController) && sender?.isMemberOfClass(Spots) == true {
            let vc = segue.destinationViewController as! SpotDetailController
            let spotObj = SpotObject().setManagedObject(sender as! Spots)
            vc.spot = spotObj
        }
        
        if segue.identifier == "toSpots" || segue.identifier == "backToSpots" || segue.identifier == "editSpot" || segue.identifier == "newSpot" {
            appDelegate.listType = "saved"
        }
        
        if segue.destinationViewController.isMemberOfClass(SpotsViewController) {
            if segue.identifier == "newSpot" {
                let spotsController = segue.destinationViewController as! SpotsViewController
                spotsController.tableView.setContentOffset(CGPointZero, animated:false)
            }

        }
        
        
    }
    

}