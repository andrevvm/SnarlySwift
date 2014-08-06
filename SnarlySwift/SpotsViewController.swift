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

class SpotsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate  {
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext
    
    var fetchedResultController: NSFetchedResultsController = NSFetchedResultsController()
    
    func getFetchedResultController() -> NSFetchedResultsController {
        fetchedResultController = NSFetchedResultsController(fetchRequest: spotFetchRequest(), managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultController
    }
    
    func spotFetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "Spots")
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return fetchRequest
    }
    
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
        self.checkSpots()
        self.refreshSpots()
        self.title = "Spots"
    }

    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        curLoc = locations[locations.endIndex - 1] as CLLocation
        curLat = NSNumber(double: curLoc.coordinate.latitude)
        curLon = NSNumber(double: curLoc.coordinate.latitude)
        
        self.parseDistance()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultController = getFetchedResultController()
        fetchedResultController.delegate = self
        fetchedResultController.performFetch(nil)
        
        self.parseImages()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        let edgeInsets = UIEdgeInsetsMake(0, 0, 100, 0)
        self.tableView.contentInset = edgeInsets
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshSpots() {
        self.parseDistance()
        self.parseImages()
    }
    
    func checkSpots() {
        if(fetchedResultController.sections[0].numberOfObjects > 0) {
            self.hasSpots()
        } else {
            println("0 results returned")
            self.emptySpots()
        }
    }
    
    func parseDistance() {
        spotDistance = []
        for spot in fetchedResultController.fetchedObjects {
            let spot = spot as Spots
            spotDistance.append(self.getDistanceString(spot))
        }
    }
    
    func parseImages() {
        spotImages = []
        for spot in fetchedResultController.fetchedObjects {
            let spot = spot as Spots
            spotImages.append(UIImage(data: spot.photo as NSData))
        }
    }
        
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections[section].numberOfObjects
    }
    
//    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
//        var cell = tableView.dequeueReusableCellWithIdentifier("SpotCell", forIndexPath: indexPath) as SpotCell
//
//        let spot = fetchedResultController.objectAtIndexPath(indexPath) as Spots
//        
//        cell.spotLabel.text = spot.title
//        
//        cell.spotLabel.text = self.spots[indexPath.row].valueForKey("title") as String
//        cell.distanceLabel.text = self.spotDistance[indexPath.row]
//        
//        if (self.spots[indexPath.row].valueForKey("photo")) {
//            cell.spotPhoto.image = self.spotImages[indexPath.row]
//        }
//        
//        cell.spotPhoto.layer.cornerRadius = 4
//        cell.spotPhoto.clipsToBounds = true
//
//        return cell
//    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell? {
        var cell = tableView.dequeueReusableCellWithIdentifier("SpotCell", forIndexPath: indexPath) as SpotCell
        let spot = fetchedResultController.objectAtIndexPath(indexPath) as Spots
        
        cell.spotLabel.text = spot.title
        
        cell.spotPhoto.image = self.spotImages[indexPath.row]
        
        if self.spotDistance.count - 1 >= indexPath.row {
            cell.distanceLabel.text = self.spotDistance[indexPath.row]
        }
        
        cell.spotPhoto.layer.cornerRadius = 4
        cell.spotPhoto.clipsToBounds = true
        
        return cell
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController!) {
        self.checkSpots()
        self.parseImages()
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        println("You selected cell #\(indexPath.row)!")
        var selectedSpot = fetchedResultController.objectAtIndexPath(indexPath) as Spots
        
        println(selectedSpot.title)
        
        performSegueWithIdentifier("spotDetail", sender: selectedSpot)
    }
    
    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        let managedObject:NSManagedObject = fetchedResultController.objectAtIndexPath(indexPath) as NSManagedObject
        managedObjectContext?.deleteObject(managedObject)
        managedObjectContext?.save(nil)
    }
    
    func getDistanceString(spot:Spots) -> NSString {
        
        if curLat == 0 && curLon == 0 {
            return ""
        }
        
        var coordinates = CLLocationCoordinate2DMake(curLat, curLon)
        var loc_lat = spot.loc_lat as Double
        var loc_lon = spot.loc_lon as Double
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
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if segue.identifier == "spotDetail" {
            let spotController:SpotDetailController = segue.destinationViewController as SpotDetailController
            spotController.spot = sender as Spots
        }
    }

}
