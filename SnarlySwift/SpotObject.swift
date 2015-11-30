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
    var userid: String?
    var object: AnyObject!
    var user: PFUser?
    var display_name: String?
    var user_photo: PFFile?
    var isPrivate: Bool!
    
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
        userid = spot.userid
        object = spot
        user = PFUser.currentUser()
        isPrivate = spot.isPrivate
        
        return self
        
    }
    
    func setParseObject(spot: PFObject) -> SpotObject {
        
        active = spot["active"] as! Bool
        bust = spot["bust"] as! Bool
        date = spot.createdAt
        distance = 0
        loc_disp = spot["loc_disp"] as? String
        loc_lat = spot["location"].latitude as Double
        loc_lon = spot["location"].longitude as Double
        notes = spot["notes"] as! String
        synced = true
        title = spot["title"] as? String
        uuid = spot.objectId
        userid = spot["user"] as? String
        object = spot
        isPrivate = spot["isPrivate"] as? Bool
        if let spotUser = spot["user"] {
            self.user = spotUser as? PFUser
        }
        if let userDisplay = spot["display_name"] {
            self.display_name = userDisplay as? String
        }
        if let userPhoto = spot["user_photo"] {
            self.user_photo = userPhoto as? PFFile
        }
    
        return self
    
    }
    
}