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
    
    func asyncRegisterView(_ grouping:YapDatabaseViewGrouping, sorting:YapDatabaseViewSorting, version:String, whiteList:Set<String>, name:DatabaseExtensionName, completionQueue:DispatchQueue?, completionBlock:((Bool) ->Void)?) {
        
        if (self.registeredExtension(name.name()) != nil ) {
            let queue:DispatchQueue = completionQueue ?? DispatchQueue.main
            if let block = completionBlock {
                queue.async(execute: { () -> Void in
                    block(true)
                })
            }
            return
        }
        
        let options = YapDatabaseViewOptions()
        options.allowedCollections = YapWhitelistBlacklist(whitelist: whiteList)
        let view = YapDatabaseView(grouping: grouping, sorting: sorting, versionTag: version, options: options)
        self.asyncRegister(view, withName: name.name(), completionQueue: completionQueue, completionBlock: completionBlock)
    }
    
    public func asyncRegisterUnsentGroupMessagesView(_ completionQueue:DispatchQueue?, completionBlock:((Bool) ->Void)?) {
        self.asyncRegisterView(YapDatabaseViewGrouping.withObjectBlock({ (readTransaction, collection, key, object) -> String! in
            guard let message = object as? OTRXMPPRoomMessage else {
                return nil
            }
            
            guard let roomId = message.roomUniqueId, message.state == .needsSending else {
                return nil
            }
            
            return roomId
            
        }), sorting: YapDatabaseViewSorting.withObjectBlock({ (readTransaction, group, collection1, key1, object1, collection2, key2, object2) -> ComparisonResult in
            
            guard let date1 = (object1 as? OTRXMPPRoomMessage)?.messageDate else {
                return .orderedSame
            }
            
            guard let date2 = (object2 as? OTRXMPPRoomMessage)?.messageDate else  {
                return .orderedSame
            }
            
            return date1.compare(date2)
        }), version: "1", whiteList: [OTRXMPPRoomMessage.collection()], name: .unsentGroupMessagesViewName, completionQueue:completionQueue, completionBlock:completionBlock)
    }
    
    public func asyncRegisterGroupOccupantsView(_ completionQueue:DispatchQueue?, completionBlock:((Bool) ->Void)?) {
        
        let grouping = YapDatabaseViewGrouping.withObjectBlock { (readTransaction, collection , key , object ) -> String! in
            guard let occupant = object as? OTRXMPPRoomOccupant else {
                return nil
            }
            
            guard let roomId = occupant.roomUniqueId else {
                return nil
            }
            
            return roomId
        }
        
        let sorting = YapDatabaseViewSorting.withObjectBlock { (readTransaction, group, collection1, key1, object1, collection2, key2, object2) -> ComparisonResult in
            
            guard let name1 = (object1 as? OTRXMPPRoomOccupant)?.realJID ?? (object1 as? OTRXMPPRoomOccupant)?.jid else {
                return .orderedSame
            }
            
            guard let name2 = (object2 as? OTRXMPPRoomOccupant)?.realJID ?? (object2 as? OTRXMPPRoomOccupant)?.jid else {
                return .orderedSame
            }
            
            return name1.localizedCompare(name2)
        }
        
        self.asyncRegisterView(grouping, sorting: sorting, version: "1", whiteList: [OTRXMPPRoomOccupant.collection()], name: .groupOccupantsViewName, completionQueue: completionQueue, completionBlock: completionBlock)
    }
}
