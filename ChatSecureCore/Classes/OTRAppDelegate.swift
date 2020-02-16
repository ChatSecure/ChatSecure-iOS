//
//  OTRAppDelegate.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 12/5/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase
import UserNotifications
import CocoaLumberjack
import UIKit
import BackgroundTasks

@available(iOS 13.0, *)
extension BGAppRefreshTaskRequest {
    static var refreshIdentifier: String {
        guard let bundleId = Bundle.main.bundleIdentifier else  {
            fatalError("No bundle identifier!")
        }
        return "\(bundleId).refresh"
    }
}


protocol BackgroundTaskProtocol {
    func setTaskCompleted(success: Bool)
}

@available(iOS 13.0, *)
extension BGTask: BackgroundTaskProtocol {}

enum FetchType {
    case fetch((UIBackgroundFetchResult)->Void)
    case task(BackgroundTaskProtocol)
}

extension OTRAppDelegate {
    @objc public func scheduleBackgroundTasks(application: UIApplication, completionHandler: ((UIBackgroundFetchResult)->Void)? = nil) {
        if let completionHandler = completionHandler {
            performBackgroundFetch(type: .fetch(completionHandler))
        }
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.cancelAllTaskRequests()
            let request = BGAppRefreshTaskRequest(identifier: BGAppRefreshTaskRequest.refreshIdentifier)
            request.earliestBeginDate = nil
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                DDLogError("BGTaskScheduler Error \(error)")
            }
            completionHandler?(.newData)
        } else if let completionHandler = completionHandler {
            self.application(application, performFetchWithCompletionHandler: completionHandler)
        }
    }

    private func performBackgroundFetch(type: FetchType)  {
        OTRProtocolManager.shared.loginAccounts(OTRAccountsManager.allAutoLoginAccounts())
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: {
            let timeout = 1.0
            OTRProtocolManager.shared.disconnectAllAccountsSocketOnly(true, timeout: timeout) {
                DispatchQueue.main.async {
                    UIApplication.shared.removeExtraForegroundNotifications()
                    switch type {
                    case .fetch(let completion):
                        completion(.newData)
                    case .task(let task):
                        task.setTaskCompleted(success: true)
                    }
                }
            }
        })
    }
    
    @objc public func configureBackgroundTasks(application: UIApplication) {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: BGAppRefreshTaskRequest.refreshIdentifier, using: nil) { (task) in
                guard let appRefreshTask = task as? BGAppRefreshTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                self.performBackgroundFetch(type: .task(appRefreshTask))
            }
        } else {
            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
    }
    
    
    /// gets the last user interaction date, or current date if app is activate
    @objc public static func getLastInteractionDate(_ block: @escaping (_ lastInteractionDate: Date?)->(), completionQueue: DispatchQueue? = nil) {
        DispatchQueue.main.async {
            var date: Date? = nil
            if UIApplication.shared.applicationState == .active {
                date = Date()
            } else {
                date = self.lastInteractionDate
            }
            if let completionQueue = completionQueue {
                completionQueue.async {
                    block(date)
                }
            } else {
                block(date)
            }
        }
    }
    
    @objc public static func setLastInteractionDate(_ date: Date) {
        DispatchQueue.main.async {
            self.lastInteractionDate = date
        }
    }

    /// @warn only access this from main queue
    private static var lastInteractionDate: Date? = nil
}

extension OTRAppDelegate {
    
    /// Returns key/collection of visible thread, or nil if not visible or unset
    @objc public static func visibleThread(_ block: @escaping (_ thread: YapCollectionKey?)->(), completionQueue: DispatchQueue? = nil) {
        DispatchQueue.main.async {
            let messagesVC = OTRAppDelegate.appDelegate.messagesViewController
            guard messagesVC.isViewLoaded,
                messagesVC.view.window != nil,
                let key = messagesVC.threadKey,
                let collection = messagesVC.threadCollection else {
                block(nil)
                return
            }
            let ck = YapCollectionKey(collection: collection, key: key)
            if let completionQueue = completionQueue {
                completionQueue.async {
                    block(ck)
                }
            } else {
                block(ck)
            }
        }
    }
    
    /// Temporary hack to fix corrupted development database. Empty incoming MAM messages were stored as unread
    @objc public func fixUnreadMessageCount(_ completion: ((_ unread: UInt) -> Void)?) {
        OTRDatabaseManager.shared.writeConnection?.asyncReadWrite({ (transaction) in
            var messagesToRemove: [OTRIncomingMessage] = []
            var messagesToMarkAsRead: [OTRIncomingMessage] = []
            transaction.enumerateUnreadMessages({ (message, stop) in
                guard let incoming = message as? OTRIncomingMessage else {
                    return
                }
                if let buddy = incoming.buddy(with: transaction),
                    let _ = buddy.account(with: transaction),
                    incoming.messageText == nil {
                    messagesToMarkAsRead.append(incoming)
                } else {
                    messagesToRemove.append(incoming)
                }
            })
            messagesToRemove.forEach({ (message) in
                DDLogInfo("Deleting orphaned message: \(message)")
                message.remove(with: transaction)
            })
            messagesToMarkAsRead.forEach({ (message) in
                DDLogInfo("Marking message with no text as read \(message)")
                if let message = message.copyAsSelf() {
                    message.read = true
                    message.save(with: transaction)
                }
            })
        }, completionBlock: {
            var unread: UInt = 0
            OTRDatabaseManager.shared.writeConnection?.asyncRead({ (transaction) in
                unread = transaction.numberOfUnreadMessages()
            }, completionBlock: {
                completion?(unread)
            })
        })
    }
    
    @objc public func enterThread(key: String, collection: String) {
        var thread: OTRThreadOwner?
        OTRDatabaseManager.shared.uiConnection?.read({ (transaction) in
            thread = transaction.object(forKey: key, inCollection: collection) as? OTRThreadOwner
        })
        if let thread = thread {
            self.splitViewCoordinator.enterConversationWithThread(thread, sender: self)
        }
    }
    
    
}

// MARK: - UNUserNotificationCenterDelegate

@available(iOS 10.0, *)
extension OTRAppDelegate: UNUserNotificationCenterDelegate {
    
    private func extractNotificationType(notification: UNNotification) -> NotificationType? {
        let userInfo = notification.request.content.userInfo
        if let rawNotificationType = userInfo[kOTRNotificationType] as? String {
            return NotificationType(rawValue: rawNotificationType)
        } else {
            return nil
        }
    }

    private func extractThreadInformation(notification: UNNotification) -> (key: String, collection: String)? {
        let userInfo = notification.request.content.userInfo
        if let threadKey = userInfo[kOTRNotificationThreadKey] as? String,
            let threadCollection = userInfo[kOTRNotificationThreadCollection] as? String {
            return (threadKey, threadCollection)
        }
        return nil
    }
    
    private func extractAccountInformation(notification: UNNotification) -> OTRXMPPAccount? {
        let userInfo = notification.request.content.userInfo
        guard let accountKey = userInfo[kOTRNotificationAccountKey] as? String else {
            return nil
        }
        var account: OTRXMPPAccount?
        OTRDatabaseManager.shared.uiConnection?.read({ (transaction) in
            account = OTRXMPPAccount.fetchObject(withUniqueID: accountKey, transaction: transaction)
        })
        return account
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let notificationType = extractNotificationType(notification: response.notification) else {
            completionHandler()
            return
        }
        
        switch notificationType {
        case .subscriptionRequest:
            splitViewCoordinator.showConversationsViewController()
        case .connectionError:
            // Show reconnection dialog for account
            if let account = extractAccountInformation(notification: response.notification) {
                splitViewCoordinator.showAccountDetails(account: account, completion: {
                    OTRProtocolManager.shared.loginAccount(account)
                })
            }
            break
        case .chatMessage, .approvedBuddy:
            if let threadInfo = extractThreadInformation(notification: response.notification) {
                enterThread(key: threadInfo.key, collection: threadInfo.collection)
            }
        }
        completionHandler()
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard let notificationType = extractNotificationType(notification: notification) else {
            // unknown notification type, so let's show one just in case?
            completionHandler([.badge, .sound, .alert])
            return
        }
        
        switch notificationType {
        case .subscriptionRequest:
            completionHandler([.badge, .sound, .alert])
        case .approvedBuddy:
            completionHandler([.badge, .sound, .alert])
        case .connectionError:
            // suppress notification when you're on the account details screen
            if let nav = splitViewCoordinator.splitViewController?.presentedViewController as? UINavigationController,
                nav.viewControllers.first is AccountDetailViewController {
                completionHandler([])
            } else {
                completionHandler([.badge, .sound, .alert])
            }
        case .chatMessage:
            // Show chat notification while user is using the app, if they aren't already looking at it
            if let (key, _) = extractThreadInformation(notification: notification) {
                OTRAppDelegate.visibleThread({ (ck) in
                    if key == ck?.key {
                        completionHandler([])
                    } else {
                        completionHandler([.badge, .sound, .alert])
                    }
                })
            }
        }
    }
}
