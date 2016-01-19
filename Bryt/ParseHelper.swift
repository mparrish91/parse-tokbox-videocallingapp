//
//  ParseHelper.swift
//  Bryt
//
//  Created by Malcolm Parrish on 11/20/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import Foundation
import Parse

class ParseHelper: NSObject {
    
    static var loginTextField: UITextField?
    static var loggedInUser: PFUser?

    static var bPollingTimerOn: Bool?
    static var activeUserobjID: String?
    static var objectsUnderDeletionQueue: NSMutableArray?
    
    
    class func anonymousLogin() {
        
        loggedInUser = PFUser.currentUser()
        if loggedInUser != nil {
            showUserTitlePrompt()
            return
        }
        PFAnonymousUtils.logInWithBlock({ (user : PFUser?, error: NSError?) -> Void in
            if error != nil || user == nil {
                let descriptiony = error?.localizedDescription
                print("Failed to login anonymously. Please try again. \(description)")
                let msg  = "Failed to save outgoing call session. Please try again \(description)"
                
                let alertController = UIAlertController(title: "LiveSessions", message: msg, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("kIncomingCallNotification", object: nil)
                })
                
                alertController.addAction(ok)
                
                let ad = UIApplication.sharedApplication().delegate as! AppDelegate
                ad.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            } else{
                loggedInUser = user!
                showUserTitlePrompt()
            }
            
        })
    }
    
    class func showUserTitlePrompt() {
        
        print(loggedInUser)

        
        let alertController = UIAlertController(title: "LiveSessions", message: "Enter your name", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            print("Ok Button Pressed")
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.userTitle = alertController.textFields![0].text
            appDelegate.bFullyLoggedIn = true
            
            //fire appdelegate timer
            appDelegate.fireListeningTimer()
            print(loggedInUser)
            NSNotificationCenter.defaultCenter().postNotificationName("kLoggedInNotification", object: nil)
        })
        
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            print("Cancel Button Pressed")
        }
        
        alertController.addAction(ok)
        alertController.addAction(cancel)
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
        }
        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
        ad.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
    }


//will initiate the call by saving session
//if there is a session already existing, do not save,
//just pop an alert

    
    class func saveSessionToParse(inputDict:Dictionary<String, AnyObject>) {
        
        print("inputDict \(inputDict)")
        
        let receiverID = inputDict["receiverID"]
        
        storeToParse(inputDict)
        
        //check if the recipient is either the caller or receiver in one of the activesessions.
        let predicate = NSPredicate(format: "receiverID = %@ OR callerID = %@", argumentArray: [receiverID!,receiverID!])
        var query = PFQuery(className:"ActiveSessions", predicate:predicate)
        
        query.getFirstObjectInBackgroundWithBlock{ (object: PFObject?, error: NSError?) -> Void in
            
            if object == nil {
                print("No session with receiverID exists.")
                storeToParse(inputDict)
            }
            else {
                NSNotificationCenter.defaultCenter().postNotificationName("kReceiverBusyNotication", object: nil)
                return
            }
        }
    }
    
    class func storeToParse(inputDict:Dictionary<String, AnyObject>) {
        
        let activeSession = PFObject(className: "ActiveSessions")
        let callerID = inputDict["callerID"]
        
        if (callerID != nil) {
            activeSession["callerID"] = callerID
        }
        
        let bAudio = inputDict["isAudio"]?.boolValue
        activeSession["isAudio"] = bAudio
        
        let bVideo = inputDict["isAudio"]?.boolValue
        activeSession["isVideo"] = bVideo                //? why was this converted to NSNumber in tutorial
        
        
        let receiverID = inputDict["receiverID"]
        if (receiverID != nil) {
            activeSession["receiverID"] = receiverID
        }
        
        
        //callerTitle
        let callerTitle = inputDict["callerTitle"]
        if (receiverID != nil) {
            activeSession["callerTitle"] = callerTitle
        }
        
        activeSession.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (error == nil) {
                print("sessionID: \(activeSession["sessionID"]), publisherToken: \(activeSession["publisherToken"]), subscriberToken: \(activeSession["subscriberToken"])")
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.sessionID = activeSession["sessionID"] as? String
                appDelegate.subscriberToken = activeSession["subscriberToken"] as? String
                appDelegate.publisherToken = activeSession["publisherToken"] as? String
                appDelegate.callerTitle = activeSession["callerTitle"] as? String
                NSNotificationCenter.defaultCenter().postNotificationName("kSessionSavedNotification", object: nil)
            } else {
                let description = error?.localizedDescription
                print("savesession error!!! \(description)")
                let msg  = "Failed to save outgoing call session. Please try again \(description)"
                
                let alertController = UIAlertController(title: "LiveSessions", message: msg, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("kIncomingCallNotification", object: nil)
                })
                
                alertController.addAction(ok)
                
                let ad = UIApplication.sharedApplication().delegate as! AppDelegate
                ad.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)

            }
        }
    }
    

    


    //FIXME: showAlert convience method This never worked
//    class func showAlert(message: String, completionClosure:((action: UIAlertAction) -> ())? = nil) {
//        let alert = UIAlertController(title: "LiveSessions", message:message, preferredStyle: UIAlertControllerStyle.Alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{(alert: UIAlertAction!) in completionClosure}))
//        
//        // add code to handle the different button hits
//        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
//        ad.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
//    }
    
    class func saveUserToParse(user: PFUser) {
        var activeUser: PFObject?
        let query = PFQuery(className: "ActiveUsers")
        query.whereKey("userID", equalTo: user.objectId!)
        query.findObjectsInBackgroundWithBlock {(objects, error) -> Void in
            if error == nil {
                //if user is active user already, just update the entry
                //otherwise create it.
                if objects?.count == 0 {
                    activeUser = PFObject(className: "ActiveUsers")
                }else{
                    activeUser = objects![0]
                }
                
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                activeUser!["userID"] = user.objectId
                activeUser!["userTitle"] = appDelegate.userTitle
                
                activeUser!.saveInBackgroundWithBlock{ (success, error) -> Void in
                    
                    if success {
                        print("activeUser saved: \(success)")
                        NSNotificationCenter.defaultCenter().postNotificationName("kSessionSavedNotification", object: nil)
                    }else{
                        let description = error?.localizedDescription
                        print(" \(description)")
                        let msg  = "Save to ActiveUsers failed. \(description)"
                        
                        let alertController = UIAlertController(title: "LiveSessions", message: msg, preferredStyle: .Alert)
                        let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName("kIncomingCallNotification", object: nil)
                        })
                        
                        alertController.addAction(ok)
                        
                        let ad = UIApplication.sharedApplication().delegate as! AppDelegate
                        ad.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)                    }
                }
            }
        }
        
    }
    
    class func pollParseForActiveSessions() {
        var activeSession: PFObject
        
        if bPollingTimerOn != nil {
            return
        }
        
        var query = PFQuery(className:"ActiveSessions")
        
        let currentUserID = loggedInUser?.objectId
        
        query.whereKey("receiverID", equalTo: currentUserID!)
        
        query.findObjectsInBackgroundWithBlock { (objects, error) -> Void in
            if error == nil {
                //if user is active user already, just update the entry
                //otherwise create it.
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                
                if objects?.count == 0 {
                    
                }else{
                    let activeSession = objects![0] as! PFObject
                    appDelegate.sessionID = activeSession["sessionID"] as? String
                    appDelegate.subscriberToken = activeSession["subscriberToken"] as? String
                    appDelegate.publisherToken = activeSession["publisherToken"] as? String
                    appDelegate.callerTitle = activeSession["callerTitle"] as? String
                    
                    
                    //done with backend object, remove it.
                    setPollingTimer(false)
                    deleteActiveSession()
                    
                    let msg  = "Incoming call from, \(appDelegate.callerTitle), Accept?"
                    
                    let alertController = UIAlertController(title: "LiveSessions", message: msg, preferredStyle: .Alert)
                    let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName("kIncomingCallNotification", object: nil)
                    })

                    alertController.addAction(ok)

                    let ad = UIApplication.sharedApplication().delegate as! AppDelegate
                    ad.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
                    
                }
            }else{
                let msg  = "Failed to retrieve active session for incoming call.  Please try again. %@ \(error?.description)"
                
                let alertController = UIAlertController(title: "LiveSessions", message: msg, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName("kIncomingCallNotification", object: nil)
                })
                
                alertController.addAction(ok)
                
                let ad = UIApplication.sharedApplication().delegate as! AppDelegate
                ad.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
            }
            
        }
    }

    class func setPollingTimer(bArg:Bool) {
        bPollingTimerOn = bArg
}
    
    class func deleteActiveSession() {
        
        print("deleteActiveSession")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let activeSessionID = appDelegate.sessionID
        
        
        if activeSessionID == nil || activeSessionID == ""{
            return
        }
        
        let query = PFQuery(className:"ActiveSessions")
        query.whereKey("sessionID", equalTo: appDelegate.sessionID!)
        
        query.getFirstObjectInBackgroundWithBlock {(object: PFObject?, error: NSError?) -> Void in
            if error != nil || object == nil {
                print("The getFirstObject request failed.")
            } else {
                // The find succeeded.
                print("Successfully retrieved the object.")
                object?.deleteInBackgroundWithBlock {(succeeded:Bool?, error: NSError?) -> Void in
                    if succeeded != nil && error == nil {
                        print("Session deleted from parse")
                    } else {
                        // The find succeeded.
                        print(error!.localizedDescription)
                    }
                }
            }
        }
    }
    
                
    


    class func deleteActiveUser() {
        let activeUserobjID = self.activeUserobjID
        
        if activeUserobjID == nil || activeUserobjID == ""{
            return
        }
        
        var query = PFQuery(className:"ActiveUsers")
        query.whereKey("userID", equalTo: activeUserobjID!)
        
        query.getFirstObjectInBackgroundWithBlock {(object:PFObject?, error:NSError?) -> Void in
            if error != nil || object == nil {
                print("The getFirstObject request failed.")
            } else {
                // The find succeeded.
                print("Successfully retrieved the object.")
                object?.deleteInBackgroundWithBlock {(succeeded:Bool?, error: NSError?) -> Void in
                    if succeeded != nil && error == nil {
                        print("User deleted from parse")
                    } else {
                        // The find succeeded.
                        print(error!.localizedDescription)
                    }
                }
            }
        }
    }



    class func initData() {
        objectsUnderDeletionQueue = NSMutableArray()
    }



class func isUnderDeletion(argObjectID:AnyObject) {
    
//properties not coming up
    
//    return objectsUnderDeletionQueue
}
}




extension Bool {
    
    func toInt () ->Int? {
        
        switch self {
            
        case false:
            
            return 0
            
        case true:
            
            return 1
            
        default:
            
            return nil
            
        }
        
    }
}



