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

class EditSpotViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate {
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext

    
    @IBOutlet var txtSpotName: UITextField!
    @IBOutlet var txtSpotNotes: UITextField!
    @IBOutlet var imagePreview : UIImageView!
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var curLat:Double = 0
    var curLon:Double = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
    }
    
    @IBAction func saveSpot(sender: UIBarButtonItem) {
        
        let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext)
        let spot = Spots(entity: entityDescripition, insertIntoManagedObjectContext: managedObjectContext)
        
        var imageData = NSData(data: UIImageJPEGRepresentation(imagePreview.image, 1.0))
        spot.title = txtSpotName.text
        spot.notes = txtSpotNotes.text
        spot.photo = imageData
        spot.loc_lat = curLat
        spot.loc_lon = curLon
        
        managedObjectContext?.save(nil)
        
        performSegueWithIdentifier("toSpots", sender: self)
    }
    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        var currentLocation = locations[locations.endIndex - 1] as CLLocation
        curLat = Double(currentLocation.coordinate.latitude)
        curLon = Double(currentLocation.coordinate.longitude)
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!) {
        let tempImage = info[UIImagePickerControllerOriginalImage] as UIImage
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
