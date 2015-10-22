//
//  SpotsViewController.swift
//  SnarlySwift
//
//  Created by Ghost on 8/4/14.
//  Copyright (c) 2014 andrevv. All rights reserved.
//

import Bolts
import UIKit
import CoreData
import CoreLocation
import AssetsLibrary
import MobileCoreServices
import Parse
import ParseUI

class SpotsViewController: UIViewController, UIImagePickerControllerDelegate, UITableViewDelegate, CLLocationManagerDelegate, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    let spotList = SpotList()
    let snarlyUser = SnarlyUser()
    
    var friendsSpots = [PFObject]()
    var friendsPhotos = [NSData]()
    
    var location: CLLocation?
    
    let editSpotsView = EditSpotViewController()
    
    
    let menuAnimationController = MenuAnimationController()
    let defaultNavigationController = UINavigationController()
    
    @IBOutlet var EmptyBg: UIImageView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var NewSpot: UIButton!
    @IBOutlet var NewSpotGradient: UIImageView!
    @IBOutlet var NavBar: UINavigationBar!
    @IBOutlet var emptyTxt: UILabel!
    @IBOutlet var loadingView: UIView!
    @IBOutlet var comingSoonView: UIView!
    @IBOutlet var comingSoonLabel: UILabel!
    @IBOutlet var faceBookBtn: UIButton!
    
    @IBOutlet var navHome: UIButton!
    @IBOutlet var navFriends: UIButton!
    @IBOutlet var navNearby: UIButton!
    @IBOutlet var navSettings: UIButton!
    var setButton: UIButton!
    
    var locationManager = CLLocationManager()
    
    var curLat:Double = 0
    var curLon:Double = 0
    var curLoc:CLLocation = CLLocation()
    var distanceNum:Double = 0.0
    
    let imag = UIImagePickerController()
    
    var refreshControl:UIRefreshControl!
    
    var firstLaunch = false
    
    let paragraphStyle = NSMutableParagraphStyle()
    
    
    @IBAction func unwindToSpots(segue: UIStoryboardSegue) {
    
    }
    
    @IBAction func unwindToSaved(sender: UIStoryboardSegue){
        
        appDelegate.listType = "saved"
        
    }
    
    @IBAction func unwindToFriends(sender: UIStoryboardSegue){
        
        appDelegate.listType = "friends"
        
    }
    
    @IBAction func selectNav(sender: UIButton){
        
        changeNav(sender)
        
    }
    
    func changeNav(btn: UIButton) {
        
        if tableView.editing {
            return
        }
        
        setButton = btn
        
        updateNav()
        
        let btnName = btn.restorationIdentifier
        
        btn.setImage(UIImage(named: "nav-\(btnName!)-active"), forState: .Normal)
        self.changeView(btn)
        
    }
    
    func updateNav() {
        
        navHome.setImage(UIImage(named: "nav-saved"), forState: .Normal)
        navFriends.setImage(UIImage(named: "nav-friends"), forState: .Normal)
        navNearby.setImage(UIImage(named: "nav-nearby"), forState: .Normal)
        navSettings.setImage(UIImage(named: "nav-settings"), forState: .Normal)
        
    }
    
    func changeView(btn: UIButton) {
        
        appDelegate.listType = btn.restorationIdentifier!
        self.reloadData()
        self.setView()
        
    }
    
    func comeHome() {
        
        changeNav(navHome)
        
    }
    
    @IBAction func capture(sender : AnyObject) {
        
        if appDelegate.location != nil {
            self.initCamera()
            self.presentViewController(imag, animated: true, completion: nil)
        } else {
            cameraError()
        }
        
    }
    
    @IBAction func library(sender : UIGestureRecognizer) {
        
        if(sender.state == UIGestureRecognizerState.Began) {
            let chooser = imag
            imag.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(chooser, animated: true, completion: nil)
        }
        
    }
    
    func initCamera() {
        imag.delegate = self
        imag.mediaTypes = [kUTTypeImage as String]
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
            imag.sourceType = UIImagePickerControllerSourceType.Camera;
            imag.allowsEditing = false
        } else {
            imag.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let tempImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let resizedImage = editSpotsView.RBResizeImage(tempImage)
        let imageData = NSData(data: UIImageJPEGRepresentation(resizedImage, 0.35)!)
        
        self.loadingView.hidden = false
        self.changeNav(navHome)
        
        self.dismissViewControllerAnimated(true, completion: {
            
            if (picker.sourceType == .PhotoLibrary) {
                self.createSpotFromLibrary(info, imageData: imageData)
            } else if (picker.sourceType == .Camera) {
                self.createSpotFromCamera(imageData)
            }
            
        })
        
    }
    
    func createSpotFromCamera(imageData:NSData) {
        
        let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
        let newSpot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
        
        newSpot.photo = imageData
        newSpot.loc_disp = appDelegate.locationString
        newSpot.active = false
        
        let newLocation = appDelegate.location
        
        if newLocation != nil {
            
            newSpot.loc_lat = (newLocation?.coordinate.latitude)!
            newSpot.loc_lon = (newLocation?.coordinate.longitude)!
            
            self.performSegueWithIdentifier("newSpot", sender: newSpot)
            
        } else {
                
            cameraError()
            
        }
        
    }
    
    func cameraError() {
        
        var locationAlert: UIAlertView
        
        locationAlert = UIAlertView(title: "Location unknown!", message: "Press & hold the add button to try adding a photo from your library instead.", delegate: self, cancelButtonTitle: "OK")
        
        locationAlert.show()
        
        self.loadingView.hidden = true
        
    }
    
    func createSpotFromLibrary(info:[String : AnyObject], imageData: NSData) {
        
        let library = ALAssetsLibrary()
        let url: NSURL = info[UIImagePickerControllerReferenceURL] as! NSURL
        
        var locationAlert: UIAlertView
        
        locationAlert = UIAlertView(title: "Location unknown!", message: "There's no location associated with the image you chose.", delegate: self, cancelButtonTitle: "OK")
        
        library.assetForURL(url, resultBlock: { (asset: ALAsset!) in
            if let asset = asset {
                if let assetLocation = asset.valueForProperty(ALAssetPropertyLocation) {
                    let latitude = (assetLocation as! CLLocation).coordinate.latitude
                    let longitude = (assetLocation as! CLLocation).coordinate.longitude
                    
                    let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: self.managedObjectContext!)
                    let newSpot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: self.managedObjectContext)
                    
                    newSpot.photo = imageData
                    newSpot.active = false
                    newSpot.loc_lat = latitude
                    newSpot.loc_lon = longitude
                    
                    self.performSegueWithIdentifier("newSpot", sender: newSpot)
                    return
                } else {
                    locationAlert.show()
                    self.loadingView.hidden = true
                }
            } else {
                
                locationAlert.show()
                self.loadingView.hidden = true
            
            }
            },
            failureBlock: { (error: NSError!) in
                print(error.localizedDescription)
            })
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(Bool())
        
        self.changeNav(setButton)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        self.setView()
        
        self.navigationController?.navigationBarHidden = false
        
        self.reloadData()
        
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if let visibleCells = tableView!.visibleCells as? [SpotCell] {
            for parallaxCell in visibleCells {
                parallax(parallaxCell)
            }
        }
        
    }
    
    
    func parallax(cell: SpotCell) {
        
        let cellY = cell.frame.origin.y
        let tableOffsetY = tableView.contentOffset.y
        
        let yOffset = ((tableOffsetY - cellY) / ImageHeight) * OffsetSpeed
        cell.spotPhoto.frame.origin.y = yOffset - 65
        
        print(cellY, tableOffsetY, cell.userOverlay.frame.origin.y, self.tableView.rowHeight)
        
        if(cellY <= (tableOffsetY - self.tableView.rowHeight + 45)) {
            cell.userOverlay.frame.origin.y = self.tableView.rowHeight - 50
        } else if(cellY <= tableOffsetY - 5) {
            cell.userOverlay.frame.origin.y = (tableOffsetY - cellY) - 5
        } else {
            cell.userOverlay.frame.origin.y = 0
        }
        

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setButton = navHome
        appDelegate.listType = "saved"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("showFriendsSpots:"), name:"retrievedFriendsSpots", object: nil);
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateCellPhoto:"), name:"retrievedSpotPhoto", object: nil);
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("userLoggedOut:"), name:"loggedOut", object: nil);
        
        initCamera()
        
        if(!NSUserDefaults.standardUserDefaults().boolForKey("firstlaunch1.0")){
            firstLaunch = true
            //Put any code here and it will be executed only once.
            //self.populateData()
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "firstlaunch1.0")
            NSUserDefaults.standardUserDefaults().synchronize();
        }
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let edgeInsets = UIEdgeInsetsMake(0, 0, 55, 0)
        self.tableView.contentInset = edgeInsets
        
        //appDelegate.setLocationVars(locationManager.location)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = UIColor.clearColor()
        self.refreshControl.tintColor = UIColor(red: 0.956, green: 0.207, blue: 0.254, alpha: 1.0)
        //self.refreshControl.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        
        let attr = [NSForegroundColorAttributeName:UIColor(red: 0.956, green: 0.207, blue: 0.254, alpha: 1.0)]
        self.refreshControl.attributedTitle = NSAttributedString(string: "Refresh location", attributes:attr)
        
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)
        
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = NSTextAlignment.Center
        
//        let user = PFUser()
//        user.username = userID
//        user.password = userID
//        
//        PFUser.logInWithUsernameInBackground(userID, password:userID) {
//            (login: PFUser?, error: NSError?) -> Void in
//            if login != nil {
//                self.syncNewSpots()
//                self.syncOutdatedSpots();
//            } else {
//                self.syncNewSpots()
//                self.syncOutdatedSpots();
//                
//                user.signUpInBackgroundWithBlock {
//                    (succeeded: Bool, error: NSError?) -> Void in
//                    if let error = error {
//                        let errorString = error.userInfo["error"] as? NSString
//                        print(errorString)
//                    } else {
//                        print("signed up!")
//                    }
//                }
//            }
//        }

        spotList.updateDistance(self)
        
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        menuAnimationController.reverse = operation == .Pop
        return menuAnimationController
    }
    
    func refresh(sender:AnyObject)
    {
        spotList.updateDistance(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        loadingView.hidden = true
        
        if(!NSUserDefaults.standardUserDefaults().boolForKey("firstlaunch1.0") == false){
            firstLaunch = false
            self.reloadData()
        }
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        
        curLoc = location!
        curLat = location!.coordinate.latitude
        curLon = location!.coordinate.longitude
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
        
    }
        
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let objCount = spotList.countObjects(section)
        
        if objCount > 0 {
            self.hasSpots()
        } else {
            self.emptySpots()
        }
        
        return objCount
        
    }
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("SpotCell", forIndexPath:indexPath) as! SpotCell
        
        spotList.configureCell(cell, atIndexPath: indexPath, loadedFriendsList: friendsSpots, loadedFriendsPhotos: friendsPhotos)
        
        parallax(cell)
        
        return cell
        
    }
    
    func updateCellPhoto(sender: NSNotification) {
    
        let int = sender.object as! Int
        
        let indexPath = NSIndexPath(forRow: int, inSection: 0)
        
        if let visibleCells = tableView!.visibleCells as? [SpotCell] {
            for (index, updateCell) in visibleCells.enumerate() {
                if(index == int) {
                    print("update!!")
                    let cell = self.tableView.cellForRowAtIndexPath(indexPath) as! SpotCell
                    cell.spotPhoto.image = UIImage(data: friendsPhotos[int])
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                }
            }
        }
        
    
    }
    
    func userLoggedOut() {
        setView()
        friendsSpots.removeAll()
        friendsPhotos.removeAll()
    }
    
    
    @available(iOS 8.0, *)
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let shareAction = UITableViewRowAction(style: .Normal, title: "      ") { (action, indexPath) -> Void in
        tableView.editing = false
            
        let spot = self.spotList.fetchedResultController.objectAtIndexPath(indexPath) as! Spots
            
        let img:UIImage = UIImage(data: spot.photo as NSData!)!
        
        let messageStr: String = "— Sent with http://getsnarly.com"
        let spotTitle: String = spot.title! + " "
        
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
        
        let editAction = UITableViewRowAction(style: .Default, title: "      ") { (action, indexPath) -> Void in
            tableView.editing = false
            let spot:NSManagedObject = self.spotList.fetchedResultController.objectAtIndexPath(indexPath) as! NSManagedObject
            self.performSegueWithIdentifier("editSpot", sender: spot)
        }
        
        editAction.backgroundColor = UIColor(patternImage: UIImage(named: "btn-edit-edit")!)
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "      ") { (action, indexPath) -> Void in
            tableView.editing = false
            
            let deleteAlert = UIAlertController(title: "Delete spot?", message: "You won't be able to recover this spot until the next time you go there!", preferredStyle: UIAlertControllerStyle.Alert)
            
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: { (action: UIAlertAction!) in
                return false
            }))
            
            deleteAlert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: { (action: UIAlertAction) in
                self.deleteSpot(indexPath)
                
            }))
            
            self.presentViewController(deleteAlert, animated: true, completion: nil)
            
        }
            
        deleteAction.backgroundColor = UIColor(patternImage: UIImage(named: "btn-edit-delete")!)
        
        if appDelegate.listType == "saved" {
            return [editAction, deleteAction, shareAction]
        } else {
            return [shareAction]
        }
    
    }
    
    func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let selectedSpot = spotList.retrieveSpot(indexPath)
        
        performSegueWithIdentifier("spotDetail", sender: selectedSpot)
        
    }
    

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            self.deleteSpot(indexPath)
        default:
            return
            
        }
    }
    
    func deleteSpot(indexPath: NSIndexPath) {
        
        spotList.deleteSpot(indexPath)
        // remove the deleted item from the `UITableView`
        self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        
    }

    
    func emptySpots() {
        tableView.hidden = true
        NewSpot.hidden = false
        NewSpotGradient.hidden = true
        EmptyBg.hidden = false
        emptyTxt.hidden = false
    }
    
    func hasSpots() {
        tableView.hidden = false
        NewSpot.hidden = false
        NewSpotGradient.hidden = true
        EmptyBg.hidden = true
        emptyTxt.hidden = true
    }
    
    func showFriendsSpots(sender: NSNotification) {
        
        loadingView.hidden = true
        
        friendsSpots = sender.object as! [PFObject]
        
        if friendsSpots.count == 0 {
            comingSoonView.hidden = false
        }
        
        for (index, spot) in friendsSpots.enumerate() {
            
            let image = UIImage(named: "EmptySpot")
            let holder = UIImagePNGRepresentation(image!)
            self.friendsPhotos.append(holder!)
            
            spot["photo"].getDataInBackgroundWithBlock({
                
                (imageData: NSData?, error: NSError?) -> Void in
                
                self.friendsPhotos[index] = imageData!
                NSNotificationCenter.defaultCenter().postNotificationName("retrievedSpotPhoto", object: index)
                
                
                
            })
        }
        
        self.reloadData()
        
    }
    
    @IBAction func populateData() {
        
//        let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
//        
//        let spot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
//        
//        let image = UIImage(named: "sample-spot")
//        let imageData = NSData(data: UIImageJPEGRepresentation(image!, 0.8)!)
//        
//        spot.title = "The Wedge hubba"
//        spot.notes = ""
//        spot.photo = imageData
//        spot.distance = 0
//        spot.bust = false
//        spot.synced = true
//        
//        spot.loc_lat = 33.466661
//        spot.loc_lon = -111.915254
//        spot.loc_disp = "Scottsdale, AZ"
//            
//        do {
//            try managedObjectContext?.save()
//        } catch _ {
//        }
        
    }
    
    func addData(title:String, url:String, lat:Double, lon:Double) {
        let entityDescripition = NSEntityDescription.entityForName("Spots", inManagedObjectContext: managedObjectContext!)
        
        let spot = Spots(entity: entityDescripition!, insertIntoManagedObjectContext: managedObjectContext)
        let image: UIImage?
        var imageData: NSData?
        
        if let url = NSURL(string: url) {
            if let data = NSData(contentsOfURL: url){
                image = UIImage(data: data)
                imageData = NSData(data: UIImageJPEGRepresentation(image!, 0.8)!)
            }
        }
    
        spot.title = title as String
        spot.notes = ""
        if (imageData != nil) {
            spot.photo = imageData!
        }
        
        spot.distance = 0
        spot.bust = false
        
        spot.loc_lat = lat
        spot.loc_lon = lon
        
        do {
            try managedObjectContext?.save()
        } catch _ {
        }
    }
    
    func reloadData() {
        
        if tableView.editing {
            return
        }
        
        tableView.reloadData()
        
    }
        
    func setActive() {
        
        let fetchRequest = NSFetchRequest(entityName: "Spots")

        let resultPredicate = NSPredicate(format: "synced = nil")
        
        let entitySpot = NSEntityDescription.entityForName("Spots", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entitySpot
        fetchRequest.predicate = resultPredicate
        
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
                    
                    spot.active = true
                    if spot.title != "The Wedge hubba" {
                        spot.synced = false
                    } else {
                        spot.synced = true
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
        }
        
    }
    
    func setView() {
        
        let viewTitle: String
        
        self.tableView.setContentOffset(CGPointZero, animated:false)
        
        switch appDelegate.listType {
            case "saved":
                viewTitle = "Your spots"
                self.tableView.rowHeight = 220.0
                comingSoonView.hidden = true
                spotList.fetchSavedSpots()
            case "friends":
                viewTitle = "Friend's spots"
                self.tableView.rowHeight = 270.0
                comingSoonView.hidden = true
                
                self.loadingView.hidden = false
                var msgText: String
                
                if snarlyUser.isFBLoggedIn() {
                    if(friendsSpots.isEmpty) {
                        spotList.retrieveFriendsSpots()
                    } else {
                        loadingView.hidden = true
                    }
                    
                    msgText = "Your friends don't have any spots yet. Invite some more on Facebook."
                    faceBookBtn.setImage(UIImage(named: "btn-invite"), forState: .Normal)
                } else {
                    loadingView.hidden = true
                    comingSoonView.hidden = false
                    msgText = "Login with Facebook to see friend's spots."
                    faceBookBtn.setImage(UIImage(named: "btn-login"), forState: .Normal)
                    
                }
                
                let attrString = NSMutableAttributedString(string: msgText)
                attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
                self.comingSoonLabel.attributedText = attrString
            
            case "nearby":
                viewTitle = "Nearby spots"
                comingSoonView.hidden = false
                var text: String
                if snarlyUser.isFBLoggedIn() {
                    text = "\(viewTitle) are coming soon, invite some friends in the meantime."
                    faceBookBtn.setImage(UIImage(named: "btn-empty-invite"), forState: .Normal)
                } else {
                    text = "\(viewTitle) are coming soon. Login with Facebook while you wait."
                    faceBookBtn.setImage(UIImage(named: "btn-login"), forState: .Normal)
                }
                
                let attrString = NSMutableAttributedString(string: text)
                attrString.addAttribute(NSParagraphStyleAttributeName, value:paragraphStyle, range:NSMakeRange(0, attrString.length))
                self.comingSoonLabel.attributedText = attrString
            default:
                viewTitle = "Your spots"
        }
        
        self.title = viewTitle
        self.tableView.reloadData()
        
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "spotDetail" {
            
            let spotController:SpotDetailController = segue.destinationViewController as! SpotDetailController
            spotController.spot = sender as? SpotObject

        }
        
        if segue.identifier == "newSpot" {
            
            let editController = segue.destinationViewController as! EditSpotViewController

            let newSpot = sender as? Spots
            editController.newSpot = newSpot
            
        }
        
        if segue.identifier == "editSpot" {
            
            let editController = segue.destinationViewController as! EditSpotViewController
            let spot = sender as? Spots
            editController.spot = spot
            
        }
        
        if segue.identifier == "showMenu" {
            navigationController?.delegate = self
        } else {
            navigationController?.delegate = defaultNavigationController.delegate
        }

        
    }
    
}
