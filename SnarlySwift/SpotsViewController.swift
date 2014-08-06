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

extension Dictionary {
    func sortedKeys(isOrderedBefore:(KeyType,KeyType) -> Bool) -> [KeyType] {
        var array = Array(self.keys)
        sort(&array, isOrderedBefore)
        return array
    }
    
    // Slower because of a lot of lookups, but probably takes less memory (this is equivalent to Pascals answer in an generic extension)
    func sortedKeysByValue(isOrderedBefore:(ValueType, ValueType) -> Bool) -> [KeyType] {
        return sortedKeys {
            isOrderedBefore(self[$0]!, self[$1]!)
        }
    }
    
    // Faster because of no lookups, may take more memory because of duplicating contents
    func keysSortedByValue(isOrderedBefore:(ValueType, ValueType) -> Bool) -> [KeyType] {
        var array = Array(self)
        sort(&array) {
            let (lk, lv) = $0
            let (rk, rv) = $1
            return isOrderedBefore(lv, rv)
        }
        return array.map {
            let (k, v) = $0
            return k
        }
    }
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
    
    var sortedKeys:NSArray = []
    var orderDict = Dictionary<NSManagedObjectID, NSNumber>()
    var distanceDict = Dictionary<NSManagedObjectID, Double>()
    var distanceStringDict = Dictionary<NSManagedObjectID, NSString>()
    var imagesDict = Dictionary<NSManagedObjectID, UIImage>()
    var spotsDict = Dictionary<NSManagedObjectID, NSManagedObject>()
    var spotImages = [UIImage]()
    var spotDistance = [NSString]()
    var curLat:NSNumber = 0
    var curLon:NSNumber = 0
    var curLoc:CLLocation = CLLocation()
    
    @IBAction func unwindToSpots(segue: UIStoryboardSegue) {
    
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(Bool())
        self.title = "Spots"
    }

    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        curLoc = locations[locations.endIndex - 1] as CLLocation
        curLat = NSNumber(double: curLoc.coordinate.latitude)
        curLon = NSNumber(double: curLoc.coordinate.latitude)
        
        self.arrangeSpots()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchSpots()
        checkSpots()
        arrangeSpots()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        let edgeInsets = UIEdgeInsetsMake(0, 0, 80, 0)
        self.tableView.contentInset = edgeInsets
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fetchSpots() {
        fetchedResultController = getFetchedResultController()
        fetchedResultController.delegate = self
        fetchedResultController.performFetch(nil)
    }
    
    func arrangeSpots() {
        var index = 0
        for spot in fetchedResultController.fetchedObjects {
            
            var spot = spot as Spots
            
            println(spot.title)
            
            var coordinates = CLLocationCoordinate2DMake(curLat, curLon)
            var loc_lat = spot.loc_lat as Double
            var loc_lon = spot.loc_lon as Double
            var location = CLLocation(latitude: loc_lat, longitude: loc_lon)
            
            var distance = curLoc.distanceFromLocation(location) as CLLocationDistance
            var distanceNum = distance.mi as Double
            
            distanceDict[spot.objectID] = distanceNum
            distanceStringDict[spot.objectID] = getDistanceString(spot)
            imagesDict[spot.objectID] = UIImage(data: spot.photo as NSData)
            spotsDict[spot.objectID] = spot
            orderDict[spot.objectID] = index
            index++
        }
        
        sortedKeys = distanceDict.sortedKeysByValue(<)
        tableView.reloadData()
    }
    
    func checkSpots() {
        if(fetchedResultController.sections[0].numberOfObjects > 0) {
            self.hasSpots()
        } else {
            println("0 results returned")
            self.emptySpots()
        }
    }
        
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections[section].numberOfObjects
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell? {
        var cell = tableView.dequeueReusableCellWithIdentifier("SpotCell", forIndexPath: indexPath) as SpotCell
        var lookup = sortedKeys[indexPath.row] as NSManagedObjectID
        let spot = spotsDict[lookup] as Spots
        
        cell.spotLabel.text = spot.title
        
        cell.spotPhoto.image = self.imagesDict[lookup]
        
        cell.distanceLabel.text = self.distanceStringDict[lookup] as NSString
        
        cell.spotPhoto.layer.cornerRadius = 4
        cell.spotPhoto.clipsToBounds = true
        
        return cell
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController!) {
        self.checkSpots()
        self.arrangeSpots()
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        var selectedSpot = fetchedResultController.objectAtIndexPath(indexPath) as Spots
        
        performSegueWithIdentifier("spotDetail", sender: selectedSpot)
    }
    
    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        
        var lookup = sortedKeys[indexPath.row] as NSManagedObjectID
        var deletedSpot = spotsDict[lookup] as Spots
        spotsDict[lookup] = nil
        distanceDict[lookup] = nil
        distanceStringDict[lookup] = nil
        imagesDict[lookup] = nil
        orderDict[lookup] = nil
        sortedKeys = distanceDict.sortedKeysByValue(<)
        
        var deletedIndexPath = fetchedResultController.indexPathForObject(deletedSpot)
        
        let managedObject:NSManagedObject = fetchedResultController.objectAtIndexPath(deletedIndexPath) as NSManagedObject
        managedObjectContext?.deleteObject(managedObject)
        managedObjectContext?.save(nil)
    }
    
    func getDistanceString(spot:Spots) -> NSString {
        
        if curLat == 0 && curLon == 0 {
            return ""
        }
        
        if spot.loc_lat == 0 && spot.loc_lon == 0 {
            return "???"
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
        if segue.identifier? == "spotDetail" {
            let spotController:SpotDetailController = segue.destinationViewController as SpotDetailController
            spotController.spot = sender as? Spots
        }
    }

}
