//
//  SpotsViewController.swift
//  SnarlySwift
//
//  Created by Ghost on 8/4/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

extension Double {
    var m: Double { return self }
    var km: Double { return self / 1_000.0 }
    var mi: Double { return self / 1_609.34 }
}

class SpotsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate  {
    
    @IBOutlet var EmptyBg: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var NewSpot: UIButton!
    @IBOutlet var NewSpotGradient: UIImageView!
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var spots:NSArray = []
    var spotImages = [UIImage]()
    var spotDistance = [NSString]()
    var curLat:NSNumber = 0
    var curLon:NSNumber = 0
    var curLoc:CLLocation = CLLocation()
    
    @IBAction func unwindToSpots(segue: UIStoryboardSegue) {
    
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(Bool())
        self.fetchSpots()
        self.checkSpots()
    }
    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        curLoc = locations[locations.endIndex - 1] as CLLocation
        curLat = NSNumber(double: curLoc.coordinate.latitude)
        curLon = NSNumber(double: curLoc.coordinate.latitude)
        
        self.fetchSpots()
        self.checkSpots()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        self.navigationController.navigationBar.barTintColor = UIColor(red: 0.956, green: 0.207, blue: 0.254, alpha: 1.0)
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 16)]
        self.navigationController.navigationBar.titleTextAttributes = titleDict
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkSpots() {
        if(spots.count > 0) {
            self.hasSpots()
            self.tableView.reloadData()
        } else {
            println("0 results returned")
            self.emptySpots()
        }
    }
    
    func fetchSpots() {
        var appDel:AppDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)
        var context:NSManagedObjectContext = appDel.managedObjectContext!
        
        var request = NSFetchRequest(entityName: "Spots")
        request.returnsObjectsAsFaults = false
        
        self.spots = context.executeFetchRequest(request, error: nil)
        
        spotImages = []
        spotDistance = []
        
        for spot in self.spots {
            spotImages.append(UIImage(data: spot.valueForKey("photo") as NSData))
            spotDistance.append(self.getDistanceString(spot))
        }
    }

        
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return self.spots.count
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        var cell = tableView.dequeueReusableCellWithIdentifier("SpotCell", forIndexPath: indexPath) as SpotCell
        
        cell.spotLabel.text = self.spots[indexPath.row].valueForKey("title") as String
        cell.distanceLabel.text = self.spotDistance[indexPath.row]
        
        if (self.spots[indexPath.row].valueForKey("photo")) {
            cell.spotPhoto.image = self.spotImages[indexPath.row]
        }
        
        cell.spotPhoto.layer.cornerRadius = 4
        cell.spotPhoto.clipsToBounds = true

        return cell
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        println("You selected cell #\(indexPath.row)!")
    }
    
    func getDistanceString(spot:AnyObject) -> NSString {
        
        if curLat == 0 && curLon == 0 {
            return ""
        }
        
        var coordinates = CLLocationCoordinate2DMake(curLat, curLon)
        var loc_lat = spot.valueForKey("loc_lat") as Double
        var loc_lon = spot.valueForKey("loc_lon") as Double
        var location = CLLocation(latitude: loc_lat, longitude: loc_lon)
        
        var distance = curLoc.distanceFromLocation(location) as CLLocationDistance
        
        var distanceDisplay:NSString = ""
        var distanceString:NSString = ""
        
        if distance.mi < 5 {
            distanceDisplay = NSString(format:"%.01f", distance.mi)
        } else {
            distanceDisplay = NSString(format:"%.00f", distance.mi)
        }
        
        if distanceDisplay == "1.0" {
            distanceString = "1 mile"
        } else if distanceDisplay == "0.0" {
            distanceString = "Here now"
        } else if distance.mi > 100 {
            distanceString = "100+ miles"
        } else {
            distanceString = "\(distanceDisplay) miles"
        }
        
        return distanceString

    }

    
    func emptySpots() {
        tableView.hidden = true
        NewSpot.hidden = true
        NewSpotGradient.hidden = true
        EmptyBg.hidden = false
    }
    
    func hasSpots() {
        tableView.hidden = false
        NewSpot.hidden = false
        NewSpotGradient.hidden = false
        EmptyBg.hidden = true
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
