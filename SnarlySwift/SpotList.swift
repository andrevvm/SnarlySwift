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
    
    var friendsSpots: [PFObject]?
    
    override init() {
        super.init()
        
        self.fetchSavedSpots()
        
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
        
        print(fetchedResultController.sections)
    }
    
    func countObjects(section: Int) -> Int {
        print(fetchedResultController.sections)
        switch appDelegate.listType {
            case "saved":
                if let fetchedSections: AnyObject = self.fetchedResultController.sections as AnyObject? {
                    print("Sections \(fetchedSections)")
                    return fetchedSections[section].numberOfObjects
                } else {
                    return 0
                }
            case "friends":
                if friendsSpots != nil {
                    return (friendsSpots?.count)!
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
        default:
            let fetchedSpot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
            spot = SpotObject().setManagedObject(fetchedSpot)
        }
        
        return spot
        
    }
    
    func deleteSpot(indexPath: NSIndexPath) {
        
        let fetchedSpot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
        
        fetchedSpot.active = false
        SnarlySpotSync().delete(fetchedSpot)

    }
    
    func configureCell(cell: SpotCell, atIndexPath indexPath: NSIndexPath, loadedFriendsList: [PFObject], loadedFriendsPhotos: [NSData] ) -> SpotCell {
        
        //let spot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
        var spot: SpotObject
        switch appDelegate.listType {
            case "saved":
                let fetchedSpot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
                spot = SpotObject().setManagedObject(fetchedSpot)
                cell.userOverlay.hidden = true
            case "friends":
                cell.userOverlay.hidden = false
                if(loadedFriendsList.isEmpty) {
                    let fetchedSpots = self.friendsSpots!
                    spot = SpotObject().setParseObject(fetchedSpots[indexPath.row])
                } else {
                    spot = SpotObject().setParseObject(loadedFriendsList[indexPath.row])
                    if(loadedFriendsPhotos.count > indexPath.row) {
                        spot.photo = loadedFriendsPhotos[indexPath.row]
                    }
                    
                }
            
            
            default:
                let fetchedSpot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
                spot = SpotObject().setManagedObject(fetchedSpot)
        }
        
        let bustIcon = cell.contentView.viewWithTag(10) as! UIImageView
        
        if (spot.bust == true) {
            bustIcon.hidden = false
        } else {
            bustIcon.hidden = true
        }
        
        cell.spotLabel.text = spot.title!
        
        let imageData = spot.photo as NSData
        cell.spotPhoto.image = UIImage(data: imageData)
        
        cell.distanceLabel.text = SnarlyUtils().getDistanceString(spot) as String
        
        if spot.loc_disp == nil {
            spot.loc_disp = ""
        }
        cell.cityLabel.text = spot.loc_disp!
        
        //cell.spotMask.layer.cornerRadius = 3
        cell.spotMask.clipsToBounds = true
        
        return cell
        
    }
    
    func showCellPhoto(sender: NSNotification) {
        
        print("cell loaded \(sender)")
        
        let object = sender.object as! [AnyObject]
        
        let cell = object[0] as! SpotCell
        let spot = object[1] as! SpotObject
        let imageData = spot.photo as NSData
        cell.spotPhoto.image = UIImage(data: imageData)
        
    }
    
    func retrieveFriendsSpots() {
        
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
                        if(self.appDelegate.location != nil) {
                            //let point = PFGeoPoint(location: self.appDelegate.location)
                            //spotsQuery.whereKey("location", nearGeoPoint: point, withinMiles: 500)
                        }
                        
                        spotsQuery.findObjectsInBackgroundWithBlock {
                            (results: [PFObject]?, error: NSError?) -> Void in
                            
                            if error == nil {
                                
                                self.friendsSpots = results
                                
                                NSNotificationCenter.defaultCenter().postNotificationName("retrievedFriendsSpots", object: results)
                                
                            } else {
                                
                            }
                        }
                        
                    }
                }
                
            }
            
            
            
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