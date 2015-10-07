//
//  AppDelegate.swift
//  SnarlySwift
//
//  Created by Ghost on 8/4/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import Parse
import ParseFacebookUtilsV4
import Bolts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
                            
    var window: UIWindow?
    
    let locationManager: CLLocationManager = CLLocationManager()
    var location: CLLocation?
    var locationString: String?
    var curLon: Double?
    var curLat: Double?
    var settingLocation: Bool = false

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        
        // Enable Local Datastore
        Parse.enableLocalDatastore()
        
        // Initialize Parse.
        Parse.setApplicationId("iuAEYOprPqDnC45lCQSlJRw096uacXs1dTbYwpOc",
            clientKey: "HVbfx7aNRg7YTTanldKKKuFojxngUzMKQPUHK0qZ")
        
        // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        //PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        locationManager.startUpdatingLocation()
        
        location = locationManager.location
        
        setLocationVars(location)
        
        setupAppearance()
    
    
        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject) -> Bool {
            return FBSDKApplicationDelegate.sharedInstance().application(
                application,
                openURL: url,
                sourceApplication: sourceApplication,
                annotation: annotation)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
        if location != nil {
            setLocationVars(location)
        }
        
    }
    
    func setLocationVars(location:CLLocation?) {
        
        if (self.locationString == nil && self.settingLocation == false && location != nil) {
            self.settingLocation = true
            getLocationString(location!.coordinate.latitude as Double, loc_lon: location!.coordinate.longitude as Double, completion: { (answer) -> Void in
                self.settingLocation = false
                self.locationString = answer
            })
        }
        
        curLon = location?.coordinate.longitude
        curLat = location?.coordinate.latitude
    }
    
    func getLocationString(loc_lat:Double, loc_lon:Double, completion: (answer: String?) -> Void) {
        
        let location = CLLocation(latitude: loc_lat, longitude: loc_lon)
        
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            if (error != nil) {
                print("Reverse geocoder failed with an error" + error!.localizedDescription)
                completion(answer: "")
            } else if placemarks!.count > 0 {
                
                let pm = placemarks?.first
                
                var area:NSString = ""
                
                if pm!.ISOcountryCode == "US" {
                    area = pm!.administrativeArea!
                } else {
                    area = pm!.country!
                }
                
                let city:NSString = pm!.locality!
                
                completion(answer: "\(city), \(area)")
            } else {
                print("Problems with the data received from geocoder.")
                completion(answer: "")
            }
        })
        
    }
    
    func setupAppearance() {
        
        UINavigationBar.appearance().barStyle = .Black

        UINavigationBar.appearance().barTintColor = UIColor(red: 0.945, green: 0.22, blue: 0.275, alpha: 1.0)
        
        
        if (UIDevice.currentDevice().systemVersion as NSString).floatValue >= 8.0 {
            
            UINavigationBar.appearance().translucent = false
        }
        
        UINavigationBar.appearance().titleTextAttributes = [NSFontAttributeName : UIFont(name: "Apercu-Bold", size: 16)!, NSForegroundColorAttributeName : UIColor.whiteColor()]

        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        
    }
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "andrevv.SnarlySwift" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.endIndex-1] 
    }()
//
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("SnarlySwift", withExtension: "momd")
        return NSManagedObjectModel(contentsOfURL: modelURL!)!
    }()

//
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SnarlySwift.sqlite")
        var storeOptions = [
            NSPersistentStoreUbiquitousContentNameKey : "SnarlySwiftStore",
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
            //NSPersistentStoreRebuildFromUbiquitousContentOption: true
        ]
        
        var failureReason = "There was an error creating or loading the application's saved data."
        
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: storeOptions)
        } catch let error as NSError {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error.userInfo)")

        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if !(coordinator != nil) {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support

    func saveContext () {
        
        do {
            let moc = self.managedObjectContext
            
            if(moc!.hasChanges) {
                try moc!.save()
            }
            
        } catch let error as NSError {
            NSLog("Unresolved error \(error), \(error.userInfo)")
        }
        
    }

}

