//
//  SpotList.swift
//  snarly
//
//  Created by Ghost on 10/8/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import CoreData
import CoreLocation
import Foundation
import Parse

class SpotList: NSObject, NSFetchedResultsControllerDelegate, CLLocationManagerDelegate {
    static let sharedInstance = SpotList()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var fetchedResultController: NSFetchedResultsController!
    
    var friendsSpots: [PFObject]? = [PFObject]()
    var nearbySpots: [PFObject]? = [PFObject]()
    
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var friendsTimer: NSTimer? = nil
    var nearbyTimer: NSTimer? = nil
    var friendsFresh: Bool?
    var nearbyFresh: Bool?
    
    let snarlyUser = SnarlyUser()
    
    override init() {
        super.init()
        
        //self.fetchSavedSpots()
        
        backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
            UIApplication.sharedApplication().endBackgroundTask(self.backgroundTaskIdentifier!)
        })
        
    }
    
    func getFetchedResultController() -> NSFetchedResultsController {
        fetchedResultController = NSFetchedResultsController(fetchRequest: spotFetchRequest(), managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultController
    }
    
    func spotFetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: "Spots")
        let resultPredicate = NSPredicate(format: "active == YES")
        let sortDescriptor1 = NSSortDescriptor(key: "distance", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor1]
        fetchRequest.predicate = resultPredicate
        
        return fetchRequest
    }
    
    func fetchSavedSpots() {
        
        fetchedResultController = getFetchedResultController()
        fetchedResultController.delegate = self
        do {
            try fetchedResultController.performFetch()
        } catch {
        }
        
    }
    
    func countObjects(section: Int) -> Int {
        
        switch appDelegate.listType {
            case "saved":
                self.fetchSavedSpots()
                if let fetchedSections: AnyObject = self.fetchedResultController.sections as AnyObject? {
                    return fetchedSections[section].numberOfObjects
                } else {
                    return 0
                }
            case "friends":
                if snarlyUser.isFBLoggedIn() {
                    return (friendsSpots?.count)!
                } else {
                    return 0
                }
            
                
            case "nearby":
                if snarlyUser.isFBLoggedIn() {
                    return (nearbySpots?.count)!
                } else {
                    return 0
                }
            
            default:
                return 0
            
        }
        
        
    }
    
    func retrieveSpot(indexPath: NSIndexPath) -> SpotObject {
        var spot: SpotObject!
        switch appDelegate.listType {
        case "saved":
            let fetchedSpot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
            spot = SpotObject().setManagedObject(fetchedSpot)
        case "friends":
            let fetchedSpot = self.friendsSpots!
            spot = SpotObject().setParseObject(fetchedSpot[indexPath.row])
        case "nearby":
            let fetchedSpot = self.nearbySpots!
            spot = SpotObject().setParseObject(fetchedSpot[indexPath.row])
        default:
            let fetchedSpot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
            spot = SpotObject().setManagedObject(fetchedSpot)
        }
        
        return spot
        
    }
    
    func deleteSpot(indexPath: NSIndexPath) {
        
        let fetchedSpot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
        
        fetchedSpot.active = false
        do {
            try self.managedObjectContext!.save()
        } catch let error as NSError {
            NSLog("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        SnarlySpotSync().delete(fetchedSpot)

    }
    
    func configureCell(cell: SpotCell, atIndexPath indexPath: NSIndexPath, loadedList: [PFObject], loadedPhotos: [NSData] ) -> SpotCell {
        
        //let spot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
        var spot: SpotObject
        switch appDelegate.listType {
            
            case "friends":
                cell.userOverlay.hidden = false
                cell.photoTop.constant = 45
                if(loadedList.isEmpty && self.friendsSpots!.count > 0) {
                    let fetchedSpots = self.friendsSpots!
                    spot = SpotObject().setParseObject(fetchedSpots[indexPath.row])
                } else {
                    spot = SpotObject().setParseObject(loadedList[indexPath.row])
                }
                if(loadedPhotos.count > indexPath.row) {
                    spot.photo = loadedPhotos[indexPath.row]
                }
            case "nearby":
                cell.userOverlay.hidden = true
                cell.photoTop.constant = 5
                if(loadedList.isEmpty && self.nearbySpots!.count > 0) {
                    let fetchedSpots = self.nearbySpots!
                    spot = SpotObject().setParseObject(fetchedSpots[indexPath.row])
                } else {
                    spot = SpotObject().setParseObject(loadedList[indexPath.row])
                }
                if(loadedPhotos.count > indexPath.row) {
                    spot.photo = loadedPhotos[indexPath.row]
                }
            
            default:
                let fetchedSpot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
                spot = SpotObject().setManagedObject(fetchedSpot)
                cell.userOverlay.hidden = true
                cell.photoTop.constant = 5
            
        }
        
        let bustIcon = cell.contentView.viewWithTag(10) as! UIImageView
        
        if (spot.bust == true) {
            bustIcon.hidden = false
        } else {
            bustIcon.hidden = true
        }
        
        cell.spotLabel.text = spot.title!
        
        if(spot.photo != nil) {
            let imageData = spot.photo as NSData
            cell.spotPhoto.image = UIImage(data: imageData)
        }
        
        cell.distanceLabel.text = SnarlyUtils().getDistanceString(spot) as String
        
        if spot.loc_disp == nil {
            spot.loc_disp = ""
        }
        cell.cityLabel.text = spot.loc_disp!
        
        //cell.spotMask.layer.cornerRadius = 3
        cell.spotMask.clipsToBounds = true
        
        return cell
        
    }
    
    func retrieveFriendsSpots(page: Int) {
        
        if (self.friendsSpots!.count > 0 && friendsFresh == true) {
            NSNotificationCenter.defaultCenter().postNotificationName("retrievedFriendsSpots", object: self.friendsSpots)
            return
        }
        
        if friendsTimer == nil {
            friendsTimer = NSTimer.scheduledTimerWithTimeInterval(600, target: self, selector: "refreshViewTimer:", userInfo: "friends", repeats: true)
        }
        
        friendsFresh = true
        
        let request: FBSDKGraphRequest = FBSDKGraphRequest.init(graphPath: "me/friends?fields=id", parameters: nil)
        request.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            
            
            
            if error == nil {

                let userList:NSDictionary = result as! NSDictionary
                let users = userList.valueForKey("data") as! NSArray
                var facebookIds = [String]()
                
                for user in users {
                    
                    let id = user["id"] as! String
                    facebookIds.append(id)
                    
                }
                
                let userQuery = PFUser.query()?.whereKey("facebookId", containedIn: facebookIds)
                
                userQuery!.findObjectsInBackgroundWithBlock {
                    (results: [PFObject]?, error: NSError?) -> Void in
                    if error == nil {
                        
                        let spotsQuery = PFQuery(className: "Spots")
                        spotsQuery.whereKey("active", equalTo: true)
                        spotsQuery.whereKey("user", containedIn: results!)
                        spotsQuery.orderByDescending("createdAt")
                        spotsQuery.limit = 15
                        spotsQuery.skip = page * spotsQuery.limit
                        
                        spotsQuery.findObjectsInBackgroundWithBlock {
                            (results: [PFObject]?, error: NSError?) -> Void in
                            
                            if error == nil {
                                
                                if page > 0 {
                                    for spot in results! {
                                        self.friendsSpots?.append(spot)
                                    }
                                } else {
                                    self.friendsSpots = results
                                }
                                
                                
                                NSNotificationCenter.defaultCenter().postNotificationName("retrievedFriendsSpots", object: self.friendsSpots)
                                
                            } else {
                                NSNotificationCenter.defaultCenter().postNotificationName("retrievedFriendsSpots", object: self.friendsSpots)
                            }
                        }
                        
                    }
                }
                
            }
            
            
            
        }
        
    }
    
    func retrieveNearbySpots(page: Int) {
        
        
        if self.nearbySpots!.count > 0 && nearbyFresh == true {
            NSNotificationCenter.defaultCenter().postNotificationName("retrievedNearbySpots", object: self.nearbySpots)
            return
        }
        
        if nearbyTimer == nil {
            nearbyTimer = NSTimer.scheduledTimerWithTimeInterval(600, target: self, selector: "refreshViewTimer:", userInfo: "nearby", repeats: true)
        }
        
        nearbyFresh = true
        
        let spotsQuery = PFQuery(className: "Spots")
        spotsQuery.whereKey("active", equalTo: true)
        //spotsQuery.orderByDescending("createdAt")
        if(self.appDelegate.location != nil) {
            let point = PFGeoPoint(location: self.appDelegate.location)
            let user = PFUser.currentUser()
            spotsQuery.whereKey("user", notEqualTo: user!)
            spotsQuery.whereKeyExists("user")
            spotsQuery.whereKey("location", nearGeoPoint: point, withinMiles: 500)
            spotsQuery.limit = 15
            spotsQuery.skip = page * spotsQuery.limit
        }
        
        spotsQuery.findObjectsInBackgroundWithBlock {
            (results: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                
                if page > 0 {
                    for spot in results! {
                        self.nearbySpots?.append(spot)
                    }
                } else {
                    self.nearbySpots = results
                }
                
                NSNotificationCenter.defaultCenter().postNotificationName("retrievedNearbySpots", object: self.nearbySpots)
                
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName("retrievedNearbySpots", object: self.nearbySpots)
            }
        }
    }
    
    func retrieveSpotPhoto(index: Int, spot: PFObject) {
        spot["photo"].getDataInBackgroundWithBlock({
            
            (imageData: NSData?, error: NSError?) -> Void in
            
            if let photo = imageData {
                let photoData:[String:AnyObject] = ["image": photo, "index": index]
                NSNotificationCenter.defaultCenter().postNotificationName("retrievedSpotPhoto", object: photoData)
            }
            
            
        })
    }
    
    func refreshViewTimer(timer: NSTimer) {
        
        let type = timer.userInfo as! String
        
        switch type {
        case "friends":
            friendsFresh = false
        case "nearby":
            nearbyFresh = false
        default:
            break
        }
        
    }

    
    func updateDistance(sender: SpotsViewController) {
        
        let curLoc = appDelegate.location
        
        if curLoc == nil {
            if let refreshControl = sender.refreshControl {
                refreshControl.endRefreshing()
                return
            } else {
                return
            }
            
        }
        
        // Create a fetch request
        
        let fetchRequest = NSFetchRequest(entityName: "Spots")
        let resultPredicate = NSPredicate(format: "active == YES")
        fetchRequest.predicate = resultPredicate
        
        // Execute the fetch request
        var error : NSError?
        var fetchedObjects: [AnyObject]?
        do {
            fetchedObjects = try self.managedObjectContext!.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error = error1
            fetchedObjects = nil
            return
        }
        
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
                    
                    let loc_lat = spot.loc_lat as Double
                    let loc_lon = spot.loc_lon as Double
                    let location = CLLocation(latitude: loc_lat, longitude: loc_lon)
                    let distance = curLoc!.distanceFromLocation(location) as CLLocationDistance
                    let distanceNum:Double = distance
                    
                    spot.distance = distanceNum
                    
                }
                
                // Save the updated managed objects into the store
                do {
                    try self.managedObjectContext!.save()
                } catch let error1 as NSError {
                    error = error1
                    NSLog("Unresolved error (error), (error!.userInfo)")
                    abort()
                }
            }
        }
        
        sender.reloadData()
        if sender.refreshControl != nil {
            sender.refreshControl.endRefreshing()
        }
        
    }
    
}