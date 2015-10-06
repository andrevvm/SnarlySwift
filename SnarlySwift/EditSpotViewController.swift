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
    var capturedImage: UIImage?

    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var txtSpotName: UITextField!
    @IBOutlet var txtSpotNotes: UITextField!
    @IBOutlet var switchBust: UISwitch!
    @IBOutlet var imagePreview : CompressedImage!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var editView: UIView!
    @IBOutlet var topConstraint: NSLayoutConstraint!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let spotSync = SnarlySpotSync()
    
    var tempImage: UIImage!
    var alreadyLoaded: Bool!
    
    var locationString: String!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        alreadyLoaded = false
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        
        if(spot != nil) {
            alreadyLoaded = true
            txtSpotName.text = spot!.title
            txtSpotNotes.text = spot!.notes
            imagePreview.image = UIImage(data: spot?.photo as NSData!)
            if spot!.bust {
                switchBust.on = true
            } else {
                switchBust.on = false
            }
            navigationBar.topItem!.title = "Edit Spot"

            
        } else {
            navigationBar.topItem!.title = "New Spot"
        }
        
        
        
        txtSpotName.attributedPlaceholder = NSAttributedString(string:"Spot name",
            attributes:[NSForegroundColorAttributeName: UIColor(red: 0.658, green: 0.607, blue: 0.611, alpha: 1.0)])
        
        txtSpotNotes.attributedPlaceholder = NSAttributedString(string:"Notes",
            attributes:[NSForegroundColorAttributeName: UIColor(red: 0.658, green: 0.607, blue: 0.611, alpha: 1.0)])
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(Bool())
        
        self.navigationController?.navigationBarHidden = false
        
        if(capturedImage != nil) {
            tempImage = capturedImage
            imagePreview.image = tempImage
        }
        
        if (tempImage != nil) {
            saveButton.enabled = true
        } else {
            saveButton.enabled = false
        }
        
        if spot != nil {
            saveButton.enabled = true
        }
    }
    
    
    
    @IBAction func saveSpot(sender: UIBarButtonItem) {
        let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
        
        if(spot == nil) {
            
            let spot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
            
            
            let resizedImage = RBResizeImage(imagePreview.image!)
            let imageData = NSData(data: UIImageJPEGRepresentation(resizedImage, 0.35)!)
            
            spot.title = txtSpotName.text
            spot.notes = txtSpotNotes.text!
            spot.photo = imageData
            spot.distance = 0
            spot.loc_disp = appDelegate.locationString
            
            if switchBust.on {
                spot.bust = true
            } else {
                spot.bust = false
            }
            
            let location = appDelegate.location
            
            if location != nil {
                spot.loc_lat = appDelegate.curLat!
                spot.loc_lon = appDelegate.curLon!
                
                do {
                    try managedObjectContext?.save()
                    self.spotSync.save(spot)
                } catch _ {
                }
                performSegueWithIdentifier("toSpots", sender: self)
                
            } else {
                
                var locationAlert: AnyObject
                
                if #available(iOS 8.0, *) {
                    locationAlert = UIAlertController(title: "Location unknown!", message: "You can save without the location, or try again to find your location.", preferredStyle: UIAlertControllerStyle.Alert)
                } else {
                
                    locationAlert = UIAlertView(title: "Location unknown!", message: "Try restarting the app to find your location.", delegate: self, cancelButtonTitle: "OK")
                
                }
                
                if #available(iOS 8.0, *) {
                    locationAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in
                        self.managedObjectContext?.deleteObject(spot)
                    }))
                } else {
                    // Fallback on earlier versions
                }
                
                if #available(iOS 8.0, *) {
                    locationAlert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction) in
                        spot.loc_lat = 0
                        spot.loc_lon = 0
                        
                        do {
                            try self.managedObjectContext?.save()
                            self.spotSync.save(spot)
                        } catch _ {
                        }
                        self.performSegueWithIdentifier("toSpots", sender: self)
                    }))
                } else {
                    // Fallback on earlier versions
                }
                
                presentViewController(locationAlert as! UIViewController, animated: true, completion: nil)
                
                
            }
            
        } else {
            
            let resizedImage = RBResizeImage(imagePreview.image!)
            let imageData = NSData(data: UIImageJPEGRepresentation(resizedImage, 0.35)!)
            
            spot!.title = txtSpotName.text
            spot!.notes = txtSpotNotes.text!
            spot!.photo = imageData
            
            if switchBust.on {
                spot!.bust = true
            } else {
                spot!.bust = false
            }
            
            do {
                try self.managedObjectContext?.save()
                if spot!.uuid != nil {
                    self.spotSync.update(spot!, objectID: spot!.uuid!)
                }
                
            } catch _ {
            }
            performSegueWithIdentifier("toSpots", sender: self)
            
        }
        
        
        
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
        
        let info = sender.userInfo!
        
        let frame = -(info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        
        self.topConstraint.constant = frame + 50
        UIView.animateWithDuration(0.5) {
            self.view.layoutIfNeeded()
        }
        
        
    }
    
    func keyboardWillHide(sender: NSNotification) {
        
        self.topConstraint.constant = 0
        UIView.animateWithDuration(0.5) {
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
        imagePreview.image=tempImage
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    func syncSpot(spot: Spots) {
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}