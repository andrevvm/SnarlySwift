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
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var type = "saved"
    
    override init() {
        
        super.init()
        
        switch type {
            case "saved":
                self.fetchSavedSpots()
            default: break
        }
        
    }
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var fetchedResultController: NSFetchedResultsController = NSFetchedResultsController()
    
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
        
        switch type {
            case "saved":
                if let fetchedSections: AnyObject = fetchedResultController.sections as AnyObject? {
                    return fetchedSections[section].numberOfObjects
                } else {
                    return 0
            }
            default:
                return 0
            
        }
        
        
    }
    
    func retrieveSpot(indexPath: NSIndexPath) -> AnyObject {
        switch type {
            case "saved":
                let spot = self.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
                return spot
            default:
                return false
        }
        
        
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
                        spotsQuery.findObjectsInBackgroundWithBlock {
                            (results: [PFObject]?, error: NSError?) -> Void in
                            
                            if error == nil {
                                
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