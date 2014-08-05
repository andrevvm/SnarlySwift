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

class EditSpotViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet var txtSpotName: UITextField!
    @IBOutlet var txtSpotNotes: UITextField!
    @IBOutlet var imagePreview : UIImageView!
    
    @IBAction func saveSpot(sender: UIBarButtonItem) {
        
        var appDel:AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        
        var newSpot = NSEntityDescription.insertNewObjectForEntityForName("Spots", inManagedObjectContext: context) as NSManagedObject
        
        var imageData = NSData(data: UIImageJPEGRepresentation(imagePreview.image, 1.0))
        newSpot.setValue(txtSpotName.text, forKey: "title")
        newSpot.setValue(txtSpotNotes.text, forKey: "notes")
        newSpot.setValue(imageData, forKey: "photo")
        
        context.save(nil)
        
        println(newSpot)
        
        performSegueWithIdentifier("toSpots", sender: self)
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!) {
        let tempImage = info[UIImagePickerControllerOriginalImage] as UIImage
        imagePreview.image=tempImage
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func capture(sender : AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
            println("Button capture")
            
            var imag = UIImagePickerController()
            imag.delegate = self
            imag.sourceType = UIImagePickerControllerSourceType.Camera;
            imag.mediaTypes = [kUTTypeImage!]
            imag.allowsEditing = false
            
            self.presentViewController(imag, animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
