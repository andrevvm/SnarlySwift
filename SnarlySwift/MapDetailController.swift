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
    
    var spot:Spots?

    override func viewDidLoad() {
        super.viewDidLoad()

        if spot?.loc_lat != 0 && spot?.loc_lon != 0 {
            let loc_lat = spot?.loc_lat as! CLLocationDegrees
            let loc_lon = spot?.loc_lon as! CLLocationDegrees
            
            let spotLati: CLLocationDegrees = loc_lat
            let spotLong: CLLocationDegrees = loc_lon
            let spotLoc = CLLocationCoordinate2DMake(spotLati, spotLong)
            let spotRegion = MKCoordinateRegionMakeWithDistance(spotLoc, 1200, 1200)
            let spotName = spot?.title
            
            self.mapView.setRegion(spotRegion, animated: true)
            ///Red Pin
            let spotPin = MKPointAnnotation()
            spotPin.coordinate = spotLoc
            spotPin.title = spotName
            self.mapView.addAnnotation(spotPin)
            
            //mapButton.addTarget(self, action: "openMap:", forControlEvents: UIControlEvents.TouchUpInside)
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
