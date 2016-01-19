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
            self.enterConversatoinWithThread(b, sender: nil)
        }
    }
    
    public func enterConversatoinWithThread(threadOwner:OTRThreadOwner, sender:AnyObject?) {
        guard let splitVC = self.splitViewController else {
            return
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as? OTRAppDelegate
        var messagesVC:OTRMessagesViewController? = nil
        if threadOwner.isGroupThread() {
            if let c = appDelegate?.theme.groupMessagesViewControllerClass() as? OTRMessagesGroupViewController.Type {
                messagesVC = c.init()
            }
            
        } else if let c = appDelegate?.theme.messagesViewControllerClass() as? OTRMessagesViewController.Type {
            messagesVC = c.init()
        }
        
        guard let mVC = messagesVC else {
            return
        }
        
        mVC.setThreadKey(threadOwner.threadIdentifier(), collection: threadOwner.threadCollection())
        let navController = UINavigationController(rootViewController: mVC)
        navController.topViewController!.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem();
        navController.topViewController!.navigationItem.leftItemsSupplementBackButton = true;
        splitVC.showDetailViewController(navController, sender: sender)
    }
    
    //MARK: OTRConversationViewControllerDelegate Methods
    public func conversationViewController(conversationViewController: OTRConversationViewController!, didSelectThread threadOwner: OTRThreadOwner!) {
        self.enterConversatoinWithThread(threadOwner, sender: conversationViewController)
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
        viewController .dismissViewControllerAnimated(true) { () -> Void in
            
            guard let buds = buddies else {
                return
            }
            
            guard let accountKey = accountId else {
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
