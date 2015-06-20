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

class SpotsViewController: UIViewController, UITableViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate  {
    
    var myData: Array<AnyObject> = []
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var fetchedResultController: NSFetchedResultsController = NSFetchedResultsController()
    
    func getFetchedResultController() -> NSFetchedResultsController {
        fetchedResultController = NSFetchedResultsController(fetchRequest: spotFetchRequest(), managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultController
    }
    
    func spotFetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "Spots")
        let sortDescriptor = NSSortDescriptor(key: "distance", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return fetchRequest
    }
    
    @IBOutlet var EmptyBg: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var NewSpot: UIButton!
    @IBOutlet var NewSpotGradient: UIImageView!
    
    var locationManager = CLLocationManager()
    
    var curLat:Double = 0
    var curLon:Double = 0
    var curLoc:CLLocation = CLLocation()
    
    
    @IBAction func unwindToSpots(segue: UIStoryboardSegue) {
    
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(Bool())
        self.title = "Spots"
        
        self.updateData()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    }
    
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        curLoc = locations[locations.endIndex - 1] as! CLLocation
        curLat = Double(curLoc.coordinate.latitude)
        curLon = Double(curLoc.coordinate.longitude)
        
        self.updateData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fetchSpots()
        self.checkSpots()
        self.setSpots()
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
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

    
    func setSpots() {
        for spot in fetchedResultController.fetchedObjects! {
            
            var spot = spot as! Spots
            
            var coordinates = CLLocationCoordinate2DMake(curLat, curLon)
            var loc_lat = spot.loc_lat as Double
            var loc_lon = spot.loc_lon as Double
            var location = CLLocation(latitude: loc_lat, longitude: loc_lon)
            
            var distance = curLoc.distanceFromLocation(location) as CLLocationDistance
            var distanceNum = distance.mi as Double
            
        }
        
        //tableView.reloadData()
    }
    
    func checkSpots() {
        if let fetchedSections: AnyObject = fetchedResultController.sections as AnyObject? {
            if(fetchedSections[0].numberOfObjects > 0) {
                self.hasSpots()
            } else {
                self.emptySpots()
            }
        }
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let fetchedSections: AnyObject = fetchedResultController.sections as AnyObject? {
            return fetchedSections.count
        } else {
            return 0
        }
    }
        
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchedSections: AnyObject = fetchedResultController.sections as AnyObject? {
            return fetchedSections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("SpotCell", forIndexPath:indexPath) as! SpotCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: SpotCell,
        atIndexPath indexPath: NSIndexPath) {
            
            let spot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
            

            cell.spotLabel.text = spot.title
            cell.spotPhoto.image = UIImage(data: spot.photo as NSData)

            
            cell.distanceLabel.text = getDistanceString(spot) as String
            
            cell.spotPhoto.layer.cornerRadius = 3
            cell.spotPhoto.clipsToBounds = true
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController!) {
        self.checkSpots()
        self.setSpots()
    }
    
    func tableView(tableView: UITableView!, editActionsForRowAtIndexPath indexPath: NSIndexPath!) -> [AnyObject]! {
        var shareAction = UITableViewRowAction(style: .Normal, title: "      ") { (action, indexPath) -> Void in
        tableView.editing = false
            
        let spot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
            
        let img:UIImage = UIImage(data: spot.photo as NSData!)!
        
        var messageStr: String = "— Sent with http://getsnarly.com"
        
        if let spotMap = NSURL(string: "http://maps.google.com/maps?q=\(spot.loc_lat),\(spot.loc_lon)"){
            let objectsToShare = [img, spotMap, messageStr]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            self.presentViewController(activityVC, animated: true, completion: nil)
            
        }
            
    }
    
    shareAction.backgroundColor = UIColor(patternImage: UIImage(named: "btn-edit-share")!)
    
    var editAction = UITableViewRowAction(style: .Default, title: "      ") { (action, indexPath) -> Void in
        tableView.editing = false
        let spot:NSManagedObject = self.fetchedResultController.objectAtIndexPath(indexPath) as! NSManagedObject
        self.performSegueWithIdentifier("editSpot", sender: spot)
    }
    
    editAction.backgroundColor = UIColor(patternImage: UIImage(named: "btn-edit-edit")!)
    
    var deleteAction = UITableViewRowAction(style: .Default, title: "      ") { (action, indexPath) -> Void in
        tableView.editing = false
        
        var deleteAlert = UIAlertController(title: "Delete spot?", message: "You won't be able to recover this spot until the next time you go there!", preferredStyle: UIAlertControllerStyle.Alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in
            return false
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { (action: UIAlertAction!) in
            let managedObject:NSManagedObject = self.fetchedResultController.objectAtIndexPath(indexPath) as! NSManagedObject
            self.managedObjectContext?.deleteObject(managedObject)
            self.managedObjectContext?.save(nil)
            
            // remove the deleted item from the `UITableView`
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }))
        
        self.presentViewController(deleteAlert, animated: true, completion: nil)
        
    }
        
    deleteAction.backgroundColor = UIColor(patternImage: UIImage(named: "btn-edit-delete")!)
    
    return [editAction, deleteAction, shareAction]
    }
    
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let managedObject:NSManagedObject = fetchedResultController.objectAtIndexPath(indexPath) as! NSManagedObject
        var selectedSpot = managedObject as! Spots
        
        performSegueWithIdentifier("spotDetail", sender: selectedSpot)
    }
    

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            let managedObject:NSManagedObject = fetchedResultController.objectAtIndexPath(indexPath) as! NSManagedObject
            managedObjectContext?.deleteObject(managedObject)
            managedObjectContext?.save(nil)

            // remove the deleted item from the `UITableView`
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        default:
            return
            
        }
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
        } else if distance.mi > 1000 {
            distanceString = "1000+ miles"
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
    
    @IBAction func populateData() {
        
        let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
        let spot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
        
        let url = NSURL(string: "http://www.skateboardingmagazine.com/wp-content/uploads/2012/02/31.jpeg")
        let data = NSData(contentsOfURL: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check
        //var image = UIImage(data: data!)
        
        spot.title = "Hubba hideout"
        spot.notes = ""
        spot.photo = data!
        spot.distance = 0
        
        spot.loc_lat = 52.49965
        spot.loc_lon = 13.45053
            
        managedObjectContext?.save(nil)
        
    }
    
    func updateData() {
        // Create a fetch request
        var fetchRequest = NSFetchRequest()
        var entitySpot = NSEntityDescription.entityForName("Spots", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entitySpot
        
        // Execute the fetch request
        var error : NSError?
        var fetchedObjects = self.managedObjectContext!.executeFetchRequest(fetchRequest, error: &error)
        
        // Change the attributer name of
        // each managed object to the self.name
        if let spots = fetchedObjects {
            if error == nil {
                for spot in spots {
                    var loc_lat = spot.loc_lat as Double
                    var loc_lon = spot.loc_lon as Double
                    var location = CLLocation(latitude: loc_lat, longitude: loc_lon)
                    var distance = curLoc.distanceFromLocation(location) as CLLocationDistance
                    var distanceNum = distance.mi as Double
                    
                    (spot as! Spots).distance = distanceNum
                }
                
                // Save the updated managed objects into the store
                if !self.managedObjectContext!.save(&error) {
                    NSLog("Unresolved error (error), (error!.userInfo)")
                    abort()
                }
            }
        }
        
        tableView.reloadData()
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "spotDetail" {
            let spotController:SpotDetailController = segue.destinationViewController as! SpotDetailController
            spotController.spot = sender as? Spots
        }
        
        if segue.identifier == "editSpot" {
            let editController = segue.destinationViewController as! EditSpotViewController
            let spot = sender as? Spots
            editController.spot = spot
        }
        
    }

}
