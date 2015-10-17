//
//  SpotSync.swift
//  snarly
//
//  Created by Ghost on 9/20/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import Foundation
import Parse
import CoreData

class SnarlySpotSync {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    func save(spot: Spots) {
        
        let PFSpot = PFObject(className: "Spots")
        
        appDelegate.getLocationString(spot.loc_lat as Double, loc_lon: spot.loc_lon as Double, completion: { (answer) -> Void in
            
            PFSpot["loc_disp"] = answer
            self.syncData(PFSpot, spot: spot, update: false)
            
        })
        
        
        
    }
    
    func update(spot: Spots, objectID: String) {
        let query = PFQuery(className:"Spots")
        query.getObjectInBackgroundWithId(objectID) {
            (PFSpot: PFObject?, error: NSError?) -> Void in
            if error != nil {
                
                self.spotNotSynced(spot)
                
            } else if let PFSpot = PFSpot {
                
                self.syncData(PFSpot, spot: spot, update: true)
                
            }
        }
    }
    
    func delete(spot: Spots, managedObject: NSManagedObject) {
        
        let objectId: String
        
        spot.active = false
        
        if(spot.uuid == nil) {
            self.managedObjectContext?.deleteObject(managedObject)
            
            do {
                try self.managedObjectContext?.save()
            } catch _ {
                
            }
        } else {
            objectId = spot.uuid!
            
            let query = PFQuery(className:"Spots")
            query.getObjectInBackgroundWithId(objectId) {
                (PFSpot: PFObject?, error: NSError?) -> Void in
                if error != nil {
                    self.spotNotSynced(spot)
                } else if let PFSpot = PFSpot {
                    
                    PFSpot["active"] = false
                    PFSpot.saveInBackgroundWithBlock { (succeeded: Bool, error: NSError?) -> Void in
                        
                        if succeeded {
                            
                            self.managedObjectContext?.deleteObject(managedObject)
                            
                            do {
                                try self.managedObjectContext?.save()
                            } catch _ {
                            }
                            
                        } else {
                            self.spotNotSynced(spot)
                        }
                        
                    }
                }
            }
            
        }
    }
    
    func spotNotSynced(spot: Spots) {
        spot.synced = false
        
        // Save the updated managed objects into the store
        do {
            try self.managedObjectContext!.save()
        } catch let error1 as NSError {
            NSLog("Unresolved error (\(error1)), (\(error1.userInfo))")
            abort()
        }
    }
    
    func syncData(PFSpot: PFObject, spot: Spots, update: Bool) {
        let lat = spot.loc_lat as Double
        let lon = spot.loc_lon as Double
        
        let Point = PFGeoPoint(latitude: lat, longitude: lon)
        
        PFSpot["bust"] = spot.bust
        if(spot.loc_disp != nil) {
            PFSpot["loc_disp"] = spot.loc_disp
        }
        
        PFSpot["notes"] = spot.notes
        
        PFSpot["active"] = spot.active
        
        if(spot.title == nil) {
            spot.title = ""
        }
        
        PFSpot["title"] = spot.title
        PFSpot["location"] = Point
        
        let currentUser = PFUser.currentUser()
        if currentUser != nil {
            PFSpot["user"] = currentUser
        } else {
            // Show the signup or login screen
        }
        
        let filename = NSUUID().UUIDString
        
        let file = PFFile(name: "\(filename).jpg", data: spot.photo)
        
        file.saveInBackgroundWithBlock { (succeeded: Bool, let error: NSError?) -> Void in
            
            if succeeded {
                
                PFSpot["photo"] = file
                
                PFSpot.saveInBackgroundWithBlock { (succeeded: Bool, error: NSError?) -> Void in
                    
                    if succeeded {
                        spot.uuid = PFSpot.objectId
                        spot.synced = true
                        
                        // Save the updated managed objects into the store
                        do {
                            try self.managedObjectContext!.save()
                        } catch let error1 as NSError {
                            NSLog("Unresolved error (\(error1)), (\(error1.userInfo))")
                            //abort()
                        }
                    } else {
                        self.spotNotSynced(spot)
                    }
                    
                }
                
            } else {
                self.spotNotSynced(spot)
            }
            
            
        }
    }
    
    func syncNewSpots() {
        
        let fetchRequest = NSFetchRequest(entityName: "Spots")
        
        let resultPredicate1 = NSPredicate(format: "synced == NO")
        let resultPredicate2 = NSPredicate(format: "uuid == nil")
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [resultPredicate1, resultPredicate2])
        fetchRequest.predicate = predicate
        
        let entitySpot = NSEntityDescription.entityForName("Spots", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entitySpot
        
        // Execute the fetch request
        var error : NSError?
        var fetchedObjects: [AnyObject]?
        do {
            fetchedObjects = try self.managedObjectContext!.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error = error1
            fetchedObjects = nil
        }
        
        // Change the attributer name of
        // each managed object to the self.name
        if let spots = fetchedObjects {
            if error == nil {
                for spot in spots {
                    
                    let spot = spot as! Spots
                    
                    SnarlySpotSync().save(spot)
                    
                    
                }
                
                
            }
        }
        
    }
    
    func syncOutdatedSpots() {
        
        let fetchRequest = NSFetchRequest(entityName: "Spots")
        
        let resultPredicate1 = NSPredicate(format: "synced == NO")
        let resultPredicate2 = NSPredicate(format: "uuid != nil")
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [resultPredicate1, resultPredicate2])
        fetchRequest.predicate = predicate
        
        let entitySpot = NSEntityDescription.entityForName("Spots", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entitySpot
        
        // Execute the fetch request
        var error : NSError?
        var fetchedObjects: [AnyObject]?
        do {
            fetchedObjects = try self.managedObjectContext!.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error = error1
            fetchedObjects = nil
        }
        
        // Change the attributer name of
        // each managed object to the self.name
        if let spots = fetchedObjects {
            if error == nil {
                for spot in spots {
                    
                    let spot = spot as! Spots
                    
                    SnarlySpotSync().update(spot, objectID: spot.uuid!)
                    
                    
                }
                
                
            }
        }
        
    }
}