//
//  SnarlyUtils.swift
//  snarly
//
//  Created by Ghost on 10/9/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import CoreData
import CoreLocation
import Foundation
import Parse

extension Double {
    var m: Double { return self }
    var km: Double { return self / 1_000.0 }
    var mi: Double { return self / 1_609.34 }
    var ft: Double { return mi * 5_280.0 }
    var mt: Double { return km * 1_000.0 }
}

class SnarlyUtils: NSObject, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate {
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var curLoc: CLLocation?
    var curLat: CLLocationDegrees?
    var curLon: CLLocationDegrees?
    
    override init() {
        
        super.init()
        
        if appDelegate.location != nil {
            curLoc = appDelegate.location!
            
            curLat = curLoc!.coordinate.latitude
            curLon = curLoc!.coordinate.longitude
        }
        
        
    }
    
    func getDistanceNum(location: CLLocation) -> CLLocationDistance? {
        
        if curLoc == nil {
            return nil
        } else {
            let distance = curLoc!.distanceFromLocation(location) as CLLocationDistance
            return distance
        }
        
    }
    
    func getDistanceString(spot:SpotObject) -> NSString {
        
        if spot.loc_lat == 0 && spot.loc_lon == 0 {
            return "???"
        }
        
        let spot_lat = spot.loc_lat as Double
        let spot_lon = spot.loc_lon as Double
        let location = CLLocation(latitude: spot_lat, longitude: spot_lon)
        
        var distance:CLLocationDistance
        
        if self.getDistanceNum(location) != nil {
            distance = curLoc!.distanceFromLocation(location) as CLLocationDistance
        } else {
            distance = spot.distance as CLLocationDistance
        }
        
        var distanceNum = distance
        
        var distanceDisplay:NSString = ""
        var distanceString:NSString = ""
        
        let locale = NSLocale.currentLocale()
        let isMetric = locale.objectForKey(NSLocaleUsesMetricSystem) as! Bool

        var distanceLabel:NSString = "mi"
        if isMetric == true {
            distanceNum = distance.km as Double
            distanceLabel = "km"
        } else {
            distanceNum = distance.mi as Double
        }
        
        var short = false;
        
        if isMetric == true && distance.mt < 500 {
            short = true;
        } else if distance.mi < 0.2 {
            short = true;
        }
        
        if distanceNum < 0.05 {
            distanceString = "Here now"
        } else if short == true {
            
            if isMetric == true {
                distanceNum = Double(round(distance.mt / 10.0) * 10)
                distanceLabel = "m"
            } else {
                distanceNum = Double(round(distance.ft / 10.0) * 10)
                distanceLabel = "ft"
            }
            
            distanceDisplay = NSString(format:"%.00f", distanceNum)
            distanceString = "\(distanceDisplay) " + (distanceLabel as String)
            
        } else if distanceNum < 2 && short == false {
            
            distanceDisplay = NSString(format:"%.01f", distanceNum)
            distanceString = "\(distanceDisplay) " + (distanceLabel as String)
            
        } else if distanceNum > 50 && distanceNum < 1500 {
            
            distanceNum = Double(round(distanceNum / 10.0) * 10)
            distanceDisplay = NSString(format:"%.00f", distanceNum)
            distanceString = "\(distanceDisplay) " + (distanceLabel as String)
            
        } else if distanceNum > 1500 {
            distanceString = "1500+ " + (distanceLabel as String)
        } else {
            distanceDisplay = NSString(format:"%.00f", distanceNum)
            distanceString = "\(distanceDisplay) " + (distanceLabel as String)
        }
        
        return distanceString
        
    }
    
    
    func roundToTens(x : Double) -> Int {
        return 10 * Int(round(x / 10.0))
    }

    
}