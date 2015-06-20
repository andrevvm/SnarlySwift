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

class EditSpotViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate {
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var spot: Spots? = nil

    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var txtSpotName: UITextField!
    @IBOutlet var txtSpotNotes: UITextField!
    @IBOutlet var imagePreview : CompressedImage!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var tempImage: UIImage!
    var alreadyLoaded: Bool!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        alreadyLoaded = false
        
        if(spot != nil) {
            alreadyLoaded = true
            txtSpotName.text = spot!.title
            txtSpotNotes.text = spot!.notes
            imagePreview.image = UIImage(data: spot?.photo as NSData!)
            navigationBar.topItem!.title = "Edit Spot"
        } else {
            navigationBar.topItem!.title = "New Spot"
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(Bool())
        
        if let tempConst = tempImage {
            saveButton.enabled = true
        } else {
            saveButton.enabled = false
            if !alreadyLoaded {
                alreadyLoaded = true
                capture(captureButton)
            }
        }
        
        if spot != nil {
            saveButton.enabled = true
        }
    }
    
    
    
    @IBAction func saveSpot(sender: UIBarButtonItem) {
        let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
        
        if(spot == nil) {
            
            let spot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
            
            var imageData = NSData(data: UIImageJPEGRepresentation(imagePreview.image, 0.2))
            
            spot.title = txtSpotName.text
            spot.notes = txtSpotNotes.text
            spot.photo = imageData
            spot.distance = 0
            
            var locationManager = appDelegate.locationManager
            var location = locationManager.location
            
            if location != nil {
                spot.loc_lat = Double(location.coordinate.latitude)
                spot.loc_lon = Double(location.coordinate.longitude)
                
                managedObjectContext?.save(nil)
                performSegueWithIdentifier("toSpots", sender: self)
                
            } else {
                
                var locationAlert = UIAlertController(title: "Location unknown!", message: "You can save without the location, or try again to find your location.", preferredStyle: UIAlertControllerStyle.Alert)
                
                locationAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in
                    self.managedObjectContext?.deleteObject(spot)
                }))
                
                locationAlert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction!) in
                    spot.loc_lat = 0
                    spot.loc_lon = 0
                    self.managedObjectContext?.save(nil)
                    self.performSegueWithIdentifier("toSpots", sender: self)
                }))
                
                presentViewController(locationAlert, animated: true, completion: nil)
                
                
            }
            
        } else {
            
            var imageData = NSData(data: UIImageJPEGRepresentation(imagePreview.image, 0.0))
            
            spot!.title = txtSpotName.text
            spot!.notes = txtSpotNotes.text
            spot!.photo = imageData
            
            performSegueWithIdentifier("toSpots", sender: self)
            
        }
        
        
        
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        tempImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        imagePreview.image=tempImage
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func capture(sender : AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
            
            var imag = UIImagePickerController()
            imag.delegate = self
            imag.sourceType = UIImagePickerControllerSourceType.Camera;
            imag.mediaTypes = [kUTTypeImage!]
            imag.allowsEditing = false
            
            self.presentViewController(imag, animated: true, completion: nil)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
