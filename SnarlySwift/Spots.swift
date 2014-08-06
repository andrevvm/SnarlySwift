//
//  Spots.swift
//  SnarlySwift
//
//  Created by Ghost on 8/6/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import Foundation
import CoreData

class Spots: NSManagedObject {

    @NSManaged var loc_lat: NSNumber
    @NSManaged var loc_lon: NSNumber
    @NSManaged var notes: String
    @NSManaged var photo: NSData
    @NSManaged var title: String

}
