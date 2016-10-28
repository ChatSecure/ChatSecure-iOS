//
//  OTRSplitViewCoordinator.swift
//  ChatSecure
//
//  Created by David Chiles on 11/30/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation

public class OTRSplitViewCoordinator: NSObject, OTRConversationViewControllerDelegate, OTRComposeViewControllerDelegate {
    
    public weak var splitViewController:UISplitViewController? = nil
    let databaseConnection:YapDatabaseConnection
    
    public init(databaseConnection:YapDatabaseConnection) {
        self.databaseConnection = databaseConnection
    }
    
    public func enterConversationWithBuddies(buddyKeys:[String], accountKey:String, name:String?) {
        guard let splitVC = self.splitViewController else {
            return
        }
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate {
            if let c = appDelegate.theme.groupMessagesViewControllerClass() as? OTRMessagesGroupViewController.Type {
                let messagesVC = c.init()
                messagesVC.setupWithBuddies(buddyKeys, accountId: accountKey, name:name)
                //setup 'back' button in nav bar
                let navigationController = UINavigationController(rootViewController: messagesVC)
                navigationController.topViewController!.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem();
                navigationController.topViewController!.navigationItem.leftItemsSupplementBackButton = true;
                splitVC.showDetailViewController(navigationController, sender: nil)
            }
        }
    }
    
    public func enterConversationWithBuddy(buddyKey:String) {
        var buddy:OTRThreadOwner? = nil
        self.databaseConnection.readWithBlock { (transaction) -> Void in
            buddy = OTRBuddy.fetchObjectWithUniqueID(buddyKey, transaction: transaction)
        }
        if let b = buddy {
            OTRProtocolManager.sharedInstance().encryptionManager.maybeRefreshOTRSessionForBuddyKey(b.threadIdentifier(), collection: b.threadCollection())
            self.enterConversationWithThread(b, sender: nil)
        }
    }
    
    public func enterConversationWithThread(threadOwner:OTRThreadOwner, sender:AnyObject?) {
        guard let splitVC = self.splitViewController else {
            return
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate
        
        var messagesViewController:OTRMessagesViewController? = appDelegate?.messagesViewController
        
        // 1. If it is a hold-to-talk now but should be a group thread the create group thread. Else if is group
        if let _  = messagesViewController as? OTRMessagesHoldTalkViewController where threadOwner.isGroupThread() {
            if let c = appDelegate?.theme.groupMessagesViewControllerClass() as? OTRMessagesGroupViewController.Type {
                messagesViewController = c.init()
            }
        } else if let _ = messagesViewController as? OTRMessagesGroupViewController where !threadOwner.isGroupThread() {
            if let c = appDelegate?.theme.messagesViewControllerClass() as? OTRMessagesViewController.Type {
                messagesViewController = c.init()
            }
        }
        
        
        guard let mVC = messagesViewController, navController = appDelegate?.messagesNavigationController else {
            return
        }
        
        OTRProtocolManager.sharedInstance().encryptionManager.maybeRefreshOTRSessionForBuddyKey(threadOwner.threadIdentifier(), collection: threadOwner.threadCollection())
        
        //Set nav controller root view controller to mVC and then show detail with nav controller
        
        mVC.setThreadKey(threadOwner.threadIdentifier(), collection: threadOwner.threadCollection())
        
        if (!navController.viewControllers.contains(mVC)) {
            navController.setViewControllers([mVC], animated: true)
        }
        
        
        navController.topViewController!.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem();
        navController.topViewController!.navigationItem.leftItemsSupplementBackButton = true;
        
        guard let viewControllers = self.splitViewController?.viewControllers  else {
            return
        }
        
        //Should we dismiss other views that may be on top of the splitviewcontroller? How?
        
        //This ensures if in actual split view side by side won't push duplicate nav controller
        if (viewControllers.contains(navController)) {
            return
        } else {
            //This works for normal pushing on to like iphone 4,5,6
            if let otherViewControllers = viewControllers.first?.childViewControllers {
                if otherViewControllers.contains(navController) {
                    return
                }
            }
        }
        
        splitVC.showDetailViewController(navController, sender: sender)
    }
    
    //MARK: OTRConversationViewControllerDelegate Methods
    public func conversationViewController(conversationViewController: OTRConversationViewController!, didSelectThread threadOwner: OTRThreadOwner!) {
        self.enterConversationWithThread(threadOwner, sender: conversationViewController)
    }
    
    public func conversationViewController(conversationViewController: OTRConversationViewController!, didSelectCompose sender: AnyObject!) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate
        var composeViewController:OTRComposeViewController? = nil
        if let c = appDelegate?.theme.composeViewControllerClass() as? OTRComposeViewController.Type {
            composeViewController = c.init()
        }
        composeViewController!.delegate = self
        let modalNavigationController = UINavigationController(rootViewController: composeViewController!)
        modalNavigationController.modalPresentationStyle = .FormSheet
        
        //May need to use conversationViewController
        self.splitViewController?.presentViewController(modalNavigationController, animated: true, completion: nil)
    }
    
    //MARK: OTRComposeViewControllerDelegate Methods
    public func controller(viewController: OTRComposeViewController, didSelectBuddies buddies: [String]?, accountId: String?, name: String?) {
        self.splitViewController?.dismissViewControllerAnimated(true) { () -> Void in
            
            guard let buds = buddies,
                accountKey = accountId else {
                return
            }
            
            if (buds.count == 1) {
                if let key = buds.first {
                    self.enterConversationWithBuddy(key)
                }
            } else if (buds.count > 1) {
                self.enterConversationWithBuddies(buds, accountKey: accountKey, name:name)
            }
        }
    }
    
    public func controllerDidCancel(viewController: OTRComposeViewController) {
        self.splitViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

/*
old delegate methods that are deprecated
#pragma mark UISplitViewControllerDelegate methods

- (void) splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
barButtonItem.title = aViewController.title;
self.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void) splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
self.navigationItem.leftBarButtonItem = nil;
}
*/
public class OTRSplitViewControllerDelegateObject: NSObject, UISplitViewControllerDelegate {
    
    public func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        
        return true
    }

    
}
