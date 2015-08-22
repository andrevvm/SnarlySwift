//
//  SpotDetailController.swift
//  SnarlySwift
//
//  Created by Ghost on 8/6/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import UIKit
import MapKit

class SpotDetailController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var spot: Spots? = nil
    
    @IBOutlet var spotPhoto: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapButton: UIButton!
    @IBOutlet var iconBust: UIImageView!
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var spotLoc: CLLocationCoordinate2D!
    var spotRegion: MKCoordinateRegion!
    var spotName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationController.navigationBar.topItem.title = ""
        if spot != nil {
            self.title = spot?.title
            if spot?.notes == "" {
                tableView.hidden = true
            } else {
                tableView.hidden = false
            }
            spotPhoto.image = UIImage(data: spot?.photo as NSData!)
            
            
            if spot?.bust == true {
                iconBust.hidden = false
            } else {
                iconBust.hidden = true
            }

            
            if spot?.loc_lat != 0 && spot?.loc_lon != 0 {
                var loc_lat = spot?.loc_lat as! CLLocationDegrees
                var loc_lon = spot?.loc_lon as! CLLocationDegrees
                
                var spotLati: CLLocationDegrees = loc_lat
                var spotLong: CLLocationDegrees = loc_lon
                spotLoc = CLLocationCoordinate2DMake(spotLati, spotLong)
                spotRegion = MKCoordinateRegionMakeWithDistance(spotLoc, 1200, 1200)
                spotName = spot?.title
                
                self.mapView.setRegion(spotRegion, animated: true)
                ///Red Pin
                var spotPin = MKPointAnnotation()
                spotPin.coordinate = spotLoc
                spotPin.title = spot?.title
                self.mapView.addAnnotation(spotPin)
                
                mapButton.addTarget(self, action: "openMap:", forControlEvents: UIControlEvents.TouchUpInside)
            }
            
            
        }
        
        let shareSelector: Selector = "shareSpot"
        
        let shareButton = UIBarButtonItem(image: UIImage(named: "btn-share"), style: .Plain, target: self, action: shareSelector)
        
        let backSelector: Selector = "backToSpots"
        
        let backButton = UIBarButtonItem(image: UIImage(named: "btn-back"), style: .Plain, target: self, action: backSelector)

        self.navigationItem.rightBarButtonItem = shareButton
        self.navigationItem.leftBarButtonItem = backButton
    }
    
    func backToSpots() {
        self.performSegueWithIdentifier("toSpots", sender: self)
    }
    
    func openMap(sender:UIButton) {
        var options = [
            MKLaunchOptionsMapCenterKey: NSValue(MKCoordinate: spotRegion.center),
            MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: spotRegion.span)
        ]
        var placemark = MKPlacemark(coordinate: spotLoc, addressDictionary: nil)
        var mapItem = MKMapItem(placemark: placemark)
        mapItem.name = spotName
        mapItem.openInMapsWithLaunchOptions(options)
    }
    
    func shareSpot() {
        
        let img: UIImage = spotPhoto.image!
        let loc = spotLoc
        
        var messageStr = "— Sent with http://getsnarly.com"
        
        var spotTitle: String = spotName + " "
        
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
        
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.estimatedRowHeight = 52.0
        tableView.rowHeight = UITableViewAutomaticDimension
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("NotesCell", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel!.text = spot?.notes
        cell.textLabel!.lineBreakMode = .ByWordWrapping
        cell.textLabel!.numberOfLines = 0;
        cell.textLabel!.textAlignment = .Center;
        cell.textLabel!.font = UIFont(name: "Apercu", size: 12)
        cell.textLabel!.backgroundColor = UIColor.whiteColor()
        cell.backgroundColor = UIColor.whiteColor()
        
        return cell
    }
    
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
    
    
}
