//
//  ParseHelper.swift
//  Bryt
//
//  Created by Malcolm Parrish on 11/20/15.
//  Copyright © 2015 Bryt. All rights reserved.
//

import Foundation
import Parse

protocol AlertProtocol : NSObjectProtocol {
    func showAlert(message: String)
}


class ParseHelper: NSObject {
    
    var delegate: AlertProtocol?

    @IBOutlet var userNameField: UITextField?
    var loginTextField: UITextField?

//will initiate the call by saving session
//if there is a session already existing, do not save,
//just pop an alert

class func saveSessionToParse(inputDict:Dictionary<String, AnyObject>) {
    
    let recieverID = inputDict["recieverID"]
    
    
    
    //check if the recipient is either the caller or receiver in one of the activesessions.
    let predicate = NSPredicate(format: "recieverID = '%@' OR callerID = %@", argumentArray: [recieverID!,recieverID!])
    var query = PFQuery(className:"ActiveSessions", predicate:predicate)
    
    query.getFirstObjectInBackgroundWithBlock{ (object: PFObject?, error: NSError?) -> Void in
        if error == nil {
            NSNotificationCenter.defaultCenter().postNotificationName("kRecieverBusyNotication", object: nil)
            return
        } else {
            print("No session with recieverID exists.")
            storeToParse(inputDict)
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
        activeSession["isAudio"] = bAudio?.toInt()
        
        let bVideo = inputDict["isAudio"]?.boolValue
        activeSession["isVideo"] = bVideo?.toInt()

        
        let recieverID = inputDict["receiverID"]
        if (recieverID != nil) {
            activeSession["recieverID"] = callerID
        }
     
        
        //callerTitle
        let callerTitle = inputDict["callerTitle"]
        if (recieverID != nil) {
            activeSession["CallerTitle"] = callerTitle
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
//                showAlert(msg)        question
            }
        }
    }



    
    
//    
//    // no way to present to VC also storage of text is messed up
//    //login prompt
    class func showUserTitlePrompt() {
        
        //present the AlertViewController
        
//        let userNameAlert = UIAlertController(title: "LiveSessions", message:"Enter your name", preferredStyle: UIAlertControllerStyle.Alert)
//        userNameAlert.addTextFieldWithConfigurationHandler(nil)
//        
//        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in
//            print("User click Ok button")  })
//        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: {(alert: UIAlertAction!) in
//            print("User click Cancel button")  })
//        
//        userNameAlert.addAction(okAction)
//        userNameAlert.addAction(cancelAction)
//        
//        
        
        let alertController = UIAlertController(title: "LiveSessions", message: "Enter your name", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            print("Ok Button Pressed")
        })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            print("Cancel Button Pressed")
        }
        alertController.addAction(ok)
        alertController.addAction(cancel)
        alertController.tag =
        alertController.addTextFieldWithConfigurationHandler { (textField) -> Void in
            // Enter the textfiled customization code here.
            loginTextField = textField
            loginTextField?.placeholder = "Enter your login ID"
        }
        let textField = alertController.textFields![0]
        textField.placeholder = "Enter your login ID"
//        presentViewController(alertController, animated: true, completion: nil)
        
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.userTitle = alertController.textFields![0].text
        appDelegate.bFullyLoggedIn = true
        
        //fire appdelegate timer
        appDelegate.fireListeningTimer()
        NSNotificationCenter.defaultCenter().postNotificationName("kLoggedInNotification", object: nil)
        
        NSNotificationCenter.defaultCenter().postNotificationName("kIncomingCallNotification", object: nil)
        
        

    
        

    
        
        //present the alert:
        //    presentViewController(alert, animated: true, completion: nil)
        
    }
    
    optional func alertView(_alertView:uialertview
//
//    
//    
//    //works
    class func anonymousLogin() {
        let loggedInUser = PFUser.currentUser()
        
        if (loggedInUser != nil) {
//            showUserTitlePrompt()
            return
        }
        
        PFAnonymousUtils.logInWithBlock({ (user : PFUser?, error: NSError?) -> Void in
            if error != nil || user == nil {
                let description = error?.localizedDescription
                print("Failed to login anonymously. Please try again. \(description)")
                let msg  = "Failed to save outgoing call session. Please try again \(description)"
//                showAlert(msg)
            } else{
                var loggedInUser = PFUser()
                loggedInUser = user!
//                showUserTitlePrompt()
            }
            
        })
    }
//
//    
//    class func showAlert(message: String){
////        let alert = UIAlertController(title: "LiveSessions", message:message, preferredStyle: UIAlertControllerStyle.Alert)
////        
////        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler:{(alert: UIAlertAction!) in print("Foo")}))
////        
//////        ViewController.presentViewController(<#T##UIViewController#>)
//        
//        if((delegate?.respondsToSelector("showAlert:")) != nil)
//        {
//            delegate?.showAlert(message)
//        }
//        
//        
//    }
//
//    func userNameEntered(alert: UIAlertAction!){
//        // store the new word
//        self.textView2.text = deletedString + " " + self.newWordField.text
//    }
//    
//    func addTextField(textField: UITextField!){
//        // add the text field and make the result global
//        textField.placeholder = "test"
////        self.newWordField = textField
//    }
//    
//    
//    
//    class func testMyAlert() {
//        anonymousLogin()
//        
//        
//        
//    }
//    

    
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