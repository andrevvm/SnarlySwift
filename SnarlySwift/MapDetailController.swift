//
//  MapDetailController.swift
//  snarly
//
//  Created by Ghost on 10/16/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import UIKit
import MapKit

class MapDetailController: UIViewController {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapButton: UIButton!
    
    var spot:SpotObject?
    var spotLoc: CLLocationCoordinate2D!
    var spotRegion: MKCoordinateRegion!
    var spotName: String!
    
    func openMap(sender:UIButton) {
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(MKCoordinate: spotRegion.center),
            MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: spotRegion.span)
        ]
        let placemark = MKPlacemark(coordinate: spotLoc, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        if spotName != "" {
            mapItem.name = spotName
        }

        mapItem.openInMapsWithLaunchOptions(options)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
            let distance = SnarlyUtils().getDistanceString(spot!) as String
            spotPin.title = "\(distance)"
            self.mapView.addAnnotation(spotPin)
            mapView.selectAnnotation(spotPin, animated: false)
            
            mapButton.addTarget(self, action: "openMap:", forControlEvents: UIControlEvents.TouchUpInside)
        } else {
            // no location
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
