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
    var ft: Double { return mi * 5_280.0 }
    var mt: Double { return km * 1_000.0 }
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
        let sortDescriptor1 = NSSortDescriptor(key: "distance", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor1]
        return fetchRequest
    }
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet var EmptyBg: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var NewSpot: UIButton!
    @IBOutlet var NewSpotGradient: UIImageView!
    
    var locationManager = CLLocationManager()
    
    var curLat:Double = 0
    var curLon:Double = 0
    var curLoc:CLLocation = CLLocation()
    
    var refreshControl:UIRefreshControl!
    
    var firstLaunch = false
    
    
    @IBAction func unwindToSpots(segue: UIStoryboardSegue) {
    
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(Bool())
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        tableView.reloadData()
        self.navigationController?.navigationBarHidden = false
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if let visibleCells = tableView!.visibleCells() as? [SpotCell] {
            for parallaxCell in visibleCells {
                parallax(parallaxCell)
            }
        }
    }
    
    func parallax(cell: SpotCell) {
    
        var yOffset = ((tableView.contentOffset.y - cell.frame.origin.y) / ImageHeight) * OffsetSpeed
        cell.spotPhoto.frame.origin.y = yOffset - 40

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //updateDistance()
        
        if(!NSUserDefaults.standardUserDefaults().boolForKey("firstlaunch1.0")){
            firstLaunch = true
            //Put any code here and it will be executed only once.
            self.populateData()
            
            self.addData("MACBA", url: "http://galaxypro.s3.amazonaws.com/spot-media/315/315-macba-skate-barcelona-spain.jpg", lat: 41.3831913, lon: 2.1668668)
            self.addData("Kulturforum", url: "https://upload.wikimedia.org/wikipedia/commons/f/f1/Berlin_Kulturforum_2002a.jpg", lat: 52.5100104, lon: 13.3698381)
            
            self.addData("3rd & Army", url: "http://www.whyelfiles.com/wf-navigator/wp-content/uploads/2013/02/IMG_7060.jpg", lat: 37.7480432, lon: -122.3890937)
            
            self.addData("Landhausplatz", url: "http://www.landezine.com/wp-content/uploads/2011/09/Landhausplatz-02-photo-guenter-wett.jpg", lat: 47.2640377, lon: 11.3961701)
            
            self.addData("Nansensgade", url: "http://quartersnacks.com/wp-content/uploads/2015/01/basketballcourt2.jpg", lat: 55.6835447, lon: 12.5651273)
            
            self.addData("Up ledges", url: "http://www.artschoolvets.com/blog/motherfuckindaviddeery/files/2010/07/DSC06594.jpg", lat: 52.496649, lon: 13.449445)
            
            self.addData("Blubba", url: "http://quartersnacks.com/wp-content/uploads/2010/05/P5180017.jpg", lat: 40.7141164, lon: -74.0034033)
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "firstlaunch1.0")
            NSUserDefaults.standardUserDefaults().synchronize();
        }
        
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
        
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        appDelegate.setLocationVars(locationManager.location)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = UIColor.clearColor()
        self.refreshControl.tintColor = UIColor(red: 0.956, green: 0.207, blue: 0.254, alpha: 1.0)
        
        var attr = [NSForegroundColorAttributeName:UIColor(red: 0.956, green: 0.207, blue: 0.254, alpha: 1.0)]
        self.refreshControl.attributedTitle = NSAttributedString(string: "Refresh location", attributes:attr)
        
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)

        
    }
    
    func refresh(sender:AnyObject)
    {
        updateDistance()
    }
    
    override func viewDidDisappear(animated: Bool) {
        if(!NSUserDefaults.standardUserDefaults().boolForKey("firstlaunch1.0") == false){
            firstLaunch = false
            tableView.reloadData()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        var location = locations.last as! CLLocation
        
        curLoc = location
        curLat = location.coordinate.latitude
        curLon = location.coordinate.longitude
        updateDistance()
        
        
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
            var loc_disp = spot.loc_disp as String?
            var loc_lat = spot.loc_lat as Double
            var loc_lon = spot.loc_lon as Double
            var location = CLLocation(latitude: loc_lat, longitude: loc_lon)
            
            var distance = curLoc.distanceFromLocation(location) as CLLocationDistance
            
            var locale = NSLocale.currentLocale()
            let isMetric = locale.objectForKey(NSLocaleUsesMetricSystem) as! Bool
            var distanceNum:Double = 0.0
            if isMetric == true {
                distanceNum = distance.km as Double
            } else {
                distanceNum = distance.mi as Double
            }
            
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
        
        parallax(cell)
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: SpotCell,
        atIndexPath indexPath: NSIndexPath) {
            
            
            
            let spot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
            
            var sampleOverlay = cell.contentView.viewWithTag(15) as! UIImageView
            
            if(firstLaunch == true && indexPath.row == 0) {
                cell.sampleOverlay.hidden = false
            } else {
                cell.sampleOverlay.hidden = true
            }
            
            var bustIcon = cell.contentView.viewWithTag(10) as! UIImageView
            
            if spot.bust {
                bustIcon.hidden = false
            } else {
                bustIcon.hidden = true
            }
            
            
            cell.spotLabel.text = spot.title
            cell.spotPhoto.image = UIImage(data: spot.photo as NSData)
            
            if appDelegate.location != nil {
                cell.distanceLabel.text = getDistanceString(spot) as String
            } else {
                cell.distanceLabel.text = ""
            }
            
            cell.cityLabel.text = spot.loc_disp
            
            //cell.spotMask.layer.cornerRadius = 3
            cell.spotMask.clipsToBounds = true
        
            
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
        var spotTitle: String = spot.title! + " "
        
        if let spotMap = NSURL(string: "http://maps.google.com/maps?q=\(spot.loc_lat),\(spot.loc_lon)"){
            let objectsToShare = [img, spotTitle, spotMap, messageStr]
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
        
        if curLat as Double == 0.0 && curLon as Double == 0.0 {
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
        
        var locale = NSLocale.currentLocale()
        let isMetric = locale.objectForKey(NSLocaleUsesMetricSystem) as! Bool
        var distanceNum:Double = 0.0
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

    
    func emptySpots() {
        tableView.hidden = true
        NewSpot.hidden = true
        NewSpotGradient.hidden = true
        EmptyBg.hidden = false
    }
    
    func hasSpots() {
        tableView.hidden = false
        NewSpot.hidden = false
        NewSpotGradient.hidden = true
        EmptyBg.hidden = true
    }
    
    @IBAction func populateData() {
        
        let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
        
        let spot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
        
        let image = UIImage(named: "sample-spot")
        var imageData = NSData(data: UIImageJPEGRepresentation(image, 0.8))
        
        spot.title = "The Wedge hubba"
        spot.notes = ""
        spot.photo = imageData
        spot.distance = 0
        spot.bust = false
        
        spot.loc_lat = 33.466661
        spot.loc_lon = -111.915254
        spot.loc_disp = "Scottsdale, AZ"
            
        managedObjectContext?.save(nil)
        
    }
    
    func addData(title:String, url:String, lat:Double, lon:Double) {
        let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
        
        let spot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
        let image: UIImage?
        var imageData: NSData?
        
        if let url = NSURL(string: url) {
            if let data = NSData(contentsOfURL: url){
                image = UIImage(data: data)
                imageData = NSData(data: UIImageJPEGRepresentation(image, 0.8))
            }
        }
    
        spot.title = title as String
        spot.notes = ""
        spot.photo = imageData!
        spot.distance = 0
        spot.bust = false
        
        spot.loc_lat = lat
        spot.loc_lon = lon
        
        managedObjectContext?.save(nil)
    }
    
    func updateDistance() {
        
        if curLat == 0 && curLon == 0 {
            
            
            if appDelegate.location != nil {
                curLoc = appDelegate.location!
                curLat = appDelegate.curLat!
                curLon = appDelegate.curLon!

            } else {
                
                var timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("updateDistance"), userInfo: nil, repeats: false)
                
                if self.refreshControl != nil {
                    self.refreshControl.endRefreshing()
                }
                
                return
            }
            
            
        }
        
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
                    
                    let spot = spot as! Spots
                    
                    //Update display location if empty
                    if spot.loc_disp == nil || spot.loc_disp == "" {
                        
                        appDelegate.getLocationString(spot.loc_lat as Double, loc_lon: spot.loc_lon as Double, completion: { (answer) -> Void in
                            
                            spot.loc_disp = answer
                            
                        })
                        
                    }
                    
                    var loc_lat = spot.loc_lat as Double
                    var loc_lon = spot.loc_lon as Double
                    var location = CLLocation(latitude: loc_lat, longitude: loc_lon)
                    var distance = curLoc.distanceFromLocation(location) as CLLocationDistance
                    var locale = NSLocale.currentLocale()
                    let isMetric = locale.objectForKey(NSLocaleUsesMetricSystem) as! Bool
                    var distanceNum:Double = distance
                    
                    spot.distance = distanceNum
                    
                }
                
                // Save the updated managed objects into the store
                if !self.managedObjectContext!.save(&error) {
                    NSLog("Unresolved error (error), (error!.userInfo)")
                    abort()
                }
            }
        }
        
        tableView.reloadData()
        if self.refreshControl != nil {
            self.refreshControl.endRefreshing()
        }
        
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
