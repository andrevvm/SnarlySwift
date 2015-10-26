//
//  SpotDetailController.swift
//  SnarlySwift
//
//  Created by Ghost on 8/6/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class SpotDetailController: UIViewController, UITableViewDelegate, UIScrollViewDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var spot: SpotObject? = nil
    var spotManaged: Spots?
    var managedObject: NSManagedObject? = nil
    
    @IBOutlet var spotPhoto: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapButton: UIButton!
    @IBOutlet var iconBust: UIImageView!
    @IBOutlet var optionsMenu: UIView!
    @IBOutlet var optionsMenuTop: NSLayoutConstraint!
    @IBOutlet var spotLocation: UILabel!
    @IBOutlet var spotNotes: UILabel!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var bustView: UIView!
    @IBOutlet var bustViewHeight: NSLayoutConstraint!
    
    @IBOutlet var photoHeight: NSLayoutConstraint!
    
    @IBOutlet var menuEditButton: UIButton!
    @IBOutlet var menuShareButton: UIButton!
    @IBOutlet var menuDeleteButton: UIButton!
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var spotLoc: CLLocationCoordinate2D!
    var spotRegion: MKCoordinateRegion!
    var spotName: String!
    
    var menu: Bool = false
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    @IBAction func unwindToSpots(unwindSegue: UIStoryboardSegue) {
        
    }
    
    @IBAction func toggleMenu() {
        
        if !menu {
            self.showMenu()
        } else {
            self.hideMenu()
        }
    }
    
    func showMenu() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.optionsMenuTop.constant = 0
            self.view.layoutIfNeeded()
            }, completion: { finished in
                self.menu = true
        })
    }
    
    func hideMenu() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.optionsMenuTop.constant = -200
            self.view.layoutIfNeeded()
            }, completion: { finished in
                self.menu = false
        })
    }
    
    func setMenu() {
        self.optionsMenuTop.constant = -200
        self.menu = false
        self.view.layoutIfNeeded()
    }
    
    func initMenuButtons() {
        
        if appDelegate.listType != "saved" {
            menuEditButton.hidden = true
            menuDeleteButton.hidden = true
        }
        
        menuEditButton.addTarget(self, action: "menuEditSpot:", forControlEvents: UIControlEvents.TouchUpInside)
        menuShareButton.addTarget(self, action: "shareSpot:", forControlEvents: UIControlEvents.TouchUpInside)
        menuDeleteButton.addTarget(self, action: "menuDeleteSpot:", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.positionPhoto()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.setMenu()
        
        self.positionPhoto()

        //self.navigationController?.navigationBarHidden = false
        if spot != nil {
            self.title = spot?.title
            
            if let photo = spot?.photo {
                spotPhoto.image = UIImage(data: photo as NSData!)
            } else {
                if spot!.object["photo"] != nil {
                    spot!.object["photo"]!.getDataInBackgroundWithBlock({
                        
                        (imageData: NSData?, error: NSError?) -> Void in
                        
                        self.spotPhoto.image = UIImage(data: imageData!)
                        
                        UIView.animateWithDuration(0.3, animations: {
                            self.spotPhoto.alpha = 1
                        })
                        
                    })
                } else {
                    self.spotPhoto.alpha = 0
                }
                
            }
            
            
            if spot?.bust == true {
                bustView.hidden = false
                bustViewHeight.constant = 50
            } else {
                bustView.hidden = true
                bustViewHeight.constant = 0
            }
            
            if spot?.notes == "" {
                
                self.spotNotes.alpha = 0.5
                
            } else {
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 6
                let attrString = NSMutableAttributedString(string: (spot?.notes)!)
                attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
                self.spotNotes.attributedText = attrString
                
                
                self.spotNotes.alpha = 1
                self.spotNotes.lineBreakMode = .ByWordWrapping
                self.spotNotes.numberOfLines = 0;
                
            }
            
            self.spotLocation.text = spot?.loc_disp
            
            if spot?.loc_lat != 0 && spot?.loc_lon != 0 {
                let loc_lat = spot?.loc_lat as! CLLocationDegrees
                let loc_lon = spot?.loc_lon as! CLLocationDegrees
                
                let spotLati: CLLocationDegrees = loc_lat
                let spotLong: CLLocationDegrees = loc_lon
                spotLoc = CLLocationCoordinate2DMake(spotLati, spotLong)
                spotRegion = MKCoordinateRegionMakeWithDistance(spotLoc, 1200, 1200)
                spotName = spot?.title
                
                self.mapView.setRegion(spotRegion, animated: true)
                ///Red Pin
                let spotPin = MKPointAnnotation()
                spotPin.coordinate = spotLoc
                spotPin.title = spot?.title
                self.mapView.addAnnotation(spotPin)
                
                //mapButton.addTarget(self, action: "openMap:", forControlEvents: UIControlEvents.TouchUpInside)
            }
            
            
            
        }

    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        positionPhoto()
        
    }
    
    func positionPhoto() {
        let offset = scrollView.contentOffset.y
        photoHeight.constant = (320 - offset)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initMenuButtons()
        
        scrollView.delegate = self
        
        //let shareSelector: Selector = "shareSpot"
        
        //let shareButton = UIBarButtonItem(image: UIImage(named: "btn-options"), style: .Plain, target: self, action: shareSelector)
        
//        let backSelector: Selector = "unwindToSpots"
//        
//        let backButton = UIBarButtonItem(image: UIImage(named: "btn-back"), style: .Plain, target: self, action: backSelector)

        //self.navigationItem.rightBarButtonItem = shareButton
        //self.navigationItem.leftBarButtonItem = backButton
        
        
    }
    
    func backToSpots() {
        self.performSegueWithIdentifier("toSpots", sender: self)
    }
    
    func openMap(sender:UIButton) {
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(MKCoordinate: spotRegion.center),
            MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: spotRegion.span)
        ]
        let placemark = MKPlacemark(coordinate: spotLoc, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = spotName
        mapItem.openInMapsWithLaunchOptions(options)
    }
    
    func shareSpot(sender:UIButton) {
        
        let img: UIImage = spotPhoto.image!
        
        let messageStr = "— Sent with http://getsnarly.com"
        
        let spotTitle: String = spotName + " "
        
        if let spotMap = NSURL(string: "http://maps.google.com/maps?q=\(spotLoc.latitude),\(spotLoc.longitude)"){
            let objectsToShare = [img,spotTitle,spotMap,messageStr]
            
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            activityVC.excludedActivityTypes = [
                UIActivityTypeAirDrop,
                UIActivityTypePostToTwitter,
                UIActivityTypePostToWeibo,
                UIActivityTypePrint,
                UIActivityTypeCopyToPasteboard,
                UIActivityTypeAssignToContact,
                UIActivityTypeAddToReadingList,
                UIActivityTypePostToFlickr,
                UIActivityTypePostToVimeo,
                UIActivityTypePostToTencentWeibo
            ]
            
            
            self.presentViewController(activityVC, animated: true, completion: nil)

        }
        
        self.toggleMenu()
        
    }
    
    func menuEditSpot(sender:UIButton) {
        
        self.performSegueWithIdentifier("editSpot", sender: nil)
        
    }
    
    func menuDeleteSpot(sender:UIButton) {
        
        if #available(iOS 8.0, *) {
            
            let deleteAlert = UIAlertController(title: "Delete spot?", message: "You won't be able to recover this spot until the next time you go there!", preferredStyle: UIAlertControllerStyle.Alert)
            
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in
                return false
            }))
            
            deleteAlert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { (action: UIAlertAction) in
                
                //self.deleteSpot()
                self.performSegueWithIdentifier("deleteSpot", sender: nil)
                
                
            }))
            
            self.presentViewController(deleteAlert, animated: true, completion: {
                
            })
            
        } else {
            
            //self.deleteSpot()
            self.performSegueWithIdentifier("deleteSpot", sender: nil)
            
            
        }
        
    }

    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        tableView.rowHeight = 50
//        return 1
//    }
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithIdentifier("NotesCell", forIndexPath: indexPath) 
//        cell.textLabel!.text = spot?.notes
//        cell.textLabel!.lineBreakMode = .ByWordWrapping
//        cell.textLabel!.numberOfLines = 0;
//        cell.textLabel!.textAlignment = .Center;
//        cell.textLabel!.font = UIFont(name: "Apercu", size: 12)
//        cell.textLabel!.backgroundColor = UIColor.whiteColor()
//        cell.backgroundColor = UIColor.whiteColor()
//        
//        return cell
//    }
    
    func mapView(mapView: MKMapView!,
        viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
            
            if annotation is MKUserLocation {
                //return nil so map view draws "blue dot" for standard user location
                return nil
            }
            
            let reuseId = "pin"
            
            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView!.canShowCallout = true
                pinView!.animatesDrop = true
                pinView!.pinColor = .Purple
            }
            else {
                pinView!.annotation = annotation
            }
            
            return pinView
    }
    
    func deleteSpot() {
        
        SnarlySpotSync().delete(self.spotManaged!)

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "editSpot" {
            
            let editController = segue.destinationViewController as! EditSpotViewController
            let spot = self.spotManaged
            editController.spot = spot
            
        }
        
        if segue.identifier == "mapDetail" {
            
            let mapController = segue.destinationViewController as! MapDetailController
            let spot = self.spot
            mapController.spot = spot
            
        }
        
    }
    
    
}
