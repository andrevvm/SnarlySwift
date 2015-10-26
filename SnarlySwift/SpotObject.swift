//
//  SpotData.swift
//  snarly
//
//  Created by Ghost on 10/17/15.
//  Copyright © 2015 andrevv. All rights reserved.
//

import CoreData
import Parse
import Foundation

class SpotObject: NSObject {
    
    var active: Bool!
    var bust: Bool!
    var date: NSDate!
    var distance: NSNumber!
    var loc_disp: String?
    var loc_lat: NSNumber!
    var loc_lon: NSNumber!
    var notes: String!
    var photo: NSData!
    var synced: Bool!
    var title: String?
    var uuid: String?
    var object: AnyObject!
    var user: PFUser!
    
    func setManagedObject(spot: Spots) -> SpotObject {
        
        active = spot.active
        bust = spot.bust
        date = spot.date
        distance = spot.distance
        loc_disp = spot.loc_disp
        loc_lat = spot.loc_lat
        loc_lon = spot.loc_lon
        notes = spot.notes
        photo = spot.photo
        synced = spot.synced
        title = spot.title
        uuid = spot.uuid
        object = spot
        user = PFUser.currentUser()
        
        return self
        
    }
    
    func setParseObject(spot: PFObject) -> SpotObject {
        
        active = spot["active"] as! Bool
        bust = spot["bust"] as! Bool
        date = spot.createdAt
        distance = 0
        loc_disp = spot["loc_disp"] as! String
        loc_lat = spot["location"].latitude as Double
        loc_lon = spot["location"].longitude as Double
        notes = spot["notes"] as! String
        synced = true
        title = spot["title"] as! String
        uuid = spot.objectId
        object = spot
        user = spot["user"] as! PFUser
    
        return self
    
    }
    
}