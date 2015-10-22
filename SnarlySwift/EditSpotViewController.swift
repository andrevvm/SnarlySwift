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
    var newSpot: Spots? = nil
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
    @IBOutlet var bottomGuide: UILabel!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var tempImage: UIImage!
    
    var location: CLLocation!
    var locationString: String!
    
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
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(Bool())
        
        self.navigationController?.navigationBarHidden = false
        
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
            navigationBar.topItem!.title = "Edit Spot"
            
        } else {
            navigationBar.topItem!.title = "New Spot"
        }
        
        saveButton.enabled = true
    }
    
    
    @IBAction func saveSpot(sender: UIBarButtonItem) {
        
        if(newSpot != nil) {
            
            let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
            let spot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
            
            let imageData = NSData(data: UIImageJPEGRepresentation(imagePreview.image!, 0.6)!)
            
            spot.title = txtSpotName.text
            spot.notes = txtSpotNotes.text!
            spot.photo = imageData
            spot.distance = 0
            spot.loc_disp = appDelegate.locationString
            spot.loc_lat = newSpot!.loc_lat
            spot.loc_lon = newSpot!.loc_lon
            spot.active = true
            
            if switchBust.on {
                spot.bust = true
            } else {
                spot.bust = false
            }
                
            do {
                try managedObjectContext?.save()
                SnarlySpotSync().save(spot)
            } catch _ {
            }
            performSegueWithIdentifier("newSpot", sender: self)
            
            
        } else {
            
            let imageData = NSData(data: UIImageJPEGRepresentation(imagePreview.image!, 0.6)!)
            
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
                    SnarlySpotSync().update(spot!, objectID: spot!.uuid!)
                }
                
            } catch _ {
            }
            performSegueWithIdentifier("editSpot", sender: self)
            
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
        
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        let offset = screenHeight - editView.frame.size.height - 210
        
        self.topConstraint.constant = frame + offset
        UIView.animateWithDuration(0.3) {
            self.view.layoutIfNeeded()
        }
        
        
    }
    
    func keyboardWillHide(sender: NSNotification) {
        
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
        
        
        if segue.identifier == "toSpots" || segue.identifier == "backToSpots" || segue.identifier == "editSpot" || segue.identifier == "newSpot" {
            appDelegate.listType = "saved"
        }
        
        if segue.identifier == "newSpot" {
            let spotsController = segue.destinationViewController as! SpotsViewController
            spotsController.tableView.setContentOffset(CGPointZero, animated:false)
        }
        
        
    }
    

}