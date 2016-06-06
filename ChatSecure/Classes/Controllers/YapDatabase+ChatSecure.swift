//
//  YapDatabse+ChatSecure.swift
//  ChatSecure
//
//  Created by David Chiles on 10/20/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import YapDatabase

public extension YapDatabase {
    
    func asyncRegisterView(grouping:YapDatabaseViewGrouping, sorting:YapDatabaseViewSorting, version:String, whiteList:Set<String>, name:DatabaseExtensionName, completionQueue:dispatch_queue_t?, completionBlock:((Bool) ->Void)?) {
        
        if (self.registeredExtension(name.name()) != nil ) {
            let queue:dispatch_queue_t = completionQueue ?? dispatch_get_main_queue()
            if let block = completionBlock {
                dispatch_async(queue, { () -> Void in
                    block(true)
                })
            }
            return
        }
        
        let options = YapDatabaseViewOptions()
        options.allowedCollections = YapWhitelistBlacklist(whitelist: whiteList)
        let view = YapDatabaseView(grouping: grouping, sorting: sorting, versionTag: version, options: options)
        self.asyncRegisterExtension(view, withName: name.name(), completionQueue: completionQueue, completionBlock: completionBlock)
    }
    
    public func asyncRegisterUnsentGroupMessagesView(completionQueue:dispatch_queue_t?, completionBlock:((Bool) ->Void)?) {
        self.asyncRegisterView(YapDatabaseViewGrouping.withObjectBlock({ (readTransaction, collection, key, object) -> String! in
            guard let message = object as? OTRXMPPRoomMessage else {
                return nil
            }
            
            guard let roomId = message.roomUniqueId where message.state == .NeedsSending else {
                return nil
            }
            
            return roomId
            
        }), sorting: YapDatabaseViewSorting.withObjectBlock({ (readTransaction, group, collection1, key1, object1, collection2, key2, object2) -> NSComparisonResult in
            
            guard let date1 = (object1 as? OTRXMPPRoomMessage)?.messageDate else {
                return .OrderedSame
            }
            
            guard let date2 = (object2 as? OTRXMPPRoomMessage)?.messageDate else  {
                return .OrderedSame
            }
            
            return date1.compare(date2)
        }), version: "1", whiteList: [OTRXMPPRoomMessage.collection()], name: .UnsentGroupMessagesViewName, completionQueue:completionQueue, completionBlock:completionBlock)
    }
    
    public func asyncRegisterGroupOccupantsView(completionQueue:dispatch_queue_t?, completionBlock:((Bool) ->Void)?) {
        
        let grouping = YapDatabaseViewGrouping.withObjectBlock { (readTransaction, collection , key , object ) -> String! in
            guard let occupant = object as? OTRXMPPRoomOccupant else {
                return nil
            }
            
            guard let roomId = occupant.roomUniqueId else {
                return nil
            }
            
            return roomId
        }
        
        let sorting = YapDatabaseViewSorting.withObjectBlock { (readTransaction, group, collection1, key1, object1, collection2, key2, object2) -> NSComparisonResult in
            
            guard let name1 = (object1 as? OTRXMPPRoomOccupant)?.realJID ?? (object1 as? OTRXMPPRoomOccupant)?.jid else {
                return .OrderedSame
            }
            
            guard let name2 = (object2 as? OTRXMPPRoomOccupant)?.realJID ?? (object2 as? OTRXMPPRoomOccupant)?.jid else {
                return .OrderedSame
            }
            
            return name1.localizedCompare(name2)
        }
        
        self.asyncRegisterView(grouping, sorting: sorting, version: "1", whiteList: [OTRXMPPRoomOccupant.collection()], name: .GroupOccupantsViewName, completionQueue: completionQueue, completionBlock: completionBlock)
    }
    
    /// The same as the normal asyncRegisterExtension except this will send out an NSNotification when registered
    public func asyncRegisterExtension(`extension`:YapDatabaseExtension, extensionName:DatabaseExtensionName, sendNotification:Bool = true, completion:((ready:Bool) -> Void)?) {
        self.asyncRegisterExtension(`extension`, withName: extensionName.name(), completionQueue: dispatch_get_main_queue(), completionBlock: { (ready) -> Void in
            
            if ready && sendNotification {
                self.sendExtensionRegisteredNotification(extensionName.name())
            }
            
            completion?(ready: ready)
        })
    }
    
    public func registerExtension(`extension`:YapDatabaseExtension, withName name:String, sendNotification:Bool = true) -> Bool {
        let success = self.registerExtension(`extension`, withName: name, connection: nil)
        if success && sendNotification {
            self.sendExtensionRegisteredNotification(name)
        }
        return success
    }
    
    private func sendExtensionRegisteredNotification(extensionName: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let name = YapDatabaseConstants.notificationName(.RegisteredExtension)
            let userInfo = [YapDatabaseConstants.notificationKeyName(.ExtensionName):extensionName]
            NSNotificationCenter.defaultCenter().postNotificationName(name, object: self, userInfo: userInfo)
        }

    }
}