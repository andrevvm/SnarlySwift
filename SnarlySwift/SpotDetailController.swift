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
    
    var locationManager: CLLocationManager = CLLocationManager()
    
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
            
            if spot?.loc_lat != 0 && spot?.loc_lon != 0 {
                var loc_lat = spot?.loc_lat as CLLocationDegrees
                var loc_lon = spot?.loc_lon as CLLocationDegrees
                
                var latitude:CLLocationDegrees = locationManager.location.coordinate.latitude
                var longitude:CLLocationDegrees = locationManager.location.coordinate.longitude
                var spotLati: CLLocationDegrees = loc_lat
                var spotLong: CLLocationDegrees = loc_lon
                var spotLoc:CLLocationCoordinate2D = CLLocationCoordinate2DMake(spotLati, spotLong)
                var theRegion:MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(spotLoc, 200, 200)
                self.mapView.setRegion(theRegion, animated: true)
                ///Red Pin
                var spotPin = MKPointAnnotation()
                spotPin.coordinate = spotLoc
                spotPin.title = "Home"
                spotPin.subtitle = "Bogdan's home"
                self.mapView.addAnnotation(spotPin)
            }
            
            
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("NotesCell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel!.text = spot?.notes
        
        cell.textLabel!.font = UIFont(name: "Avenir-Roman", size: 14)
        
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
