//
//  RoomManager.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 11/17/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

public extension OTRXMPPRoomManager {
    
    @objc public func join(room: OTRXMPPRoom) {
        guard let roomJID = room.roomJID else { return }
        joinRoom(roomJID, withNickname: nil, subject: room.subject, password: room.roomPassword)
    }
    
    private func roomForBookmark(_ bookmark: XMPPBookmark) -> OTRXMPPRoom? {
        guard let conference = bookmark as? XMPPConferenceBookmark,
            let jidString = conference.jid?.bare,
            let accountId = self.accountId else {
                return nil
        }
        let room = OTRXMPPRoom()!
        room.accountUniqueId = accountId
        room.jid = jidString
        room.subject = conference.bookmarkName
        room.roomPassword = conference.password
        return room
    }
    
    private var accountId: String? {
        return xmppStream?.tag as? String
    }
    
    private func handleIncomingBookmarks(_ bookmarks: [XMPPBookmark]) {
        var incomingRooms: [OTRXMPPRoom] = []
        
        bookmarks.forEach({ (bookmark) in
            if let room = self.roomForBookmark(bookmark) {
                incomingRooms.append(room)
            }
        })
        guard incomingRooms.count > 0 else {
            return
        }
        var rooms: [OTRXMPPRoom] = []
        self.databaseConnection?.asyncReadWrite({ (transaction) in
            incomingRooms.forEach({ (room) in
                // Don't overwrite existing rooms with incoming rooms
                if let existingRoom = OTRXMPPRoom.fetchObject(withUniqueID: room.uniqueId, transaction: transaction) {
                    rooms.append(existingRoom)
                } else {
                    rooms.append(room)
                    room.save(with: transaction)
                }
            })
        }, completionBlock: {
            rooms.forEach({ (room) in
                self.join(room: room)
            })
        })
    }
    
    @objc public func addRoomsToBookmarks(_ rooms: [OTRXMPPRoom]) {
        var bookmarks: [XMPPConferenceBookmark] = []
        rooms.forEach { (room) in
            if let bookmark = room.bookmark {
                bookmarks.append(bookmark)
            }
        }
        bookmarksModule.fetchAndPublish(bookmarksToAdd: bookmarks, completion: { (newBookmarks, responseIq) in
            guard let outBookmarks = newBookmarks else {
                DDLogError("Failed to add bookmarks \(bookmarks)")
                return
            }
            DDLogInfo("New bookmarks \(outBookmarks)")
            self.handleIncomingBookmarks(outBookmarks)
        })
    }
    
    @objc public func removeRoomsFromBookmarks(_ rooms: [OTRXMPPRoom]) {
        var bookmarks: [XMPPConferenceBookmark] = []
        rooms.forEach { (room) in
            if let bookmark = room.bookmark {
                bookmarks.append(bookmark)
            }
        }
        bookmarksModule.fetchAndPublish(bookmarksToAdd: [], bookmarksToRemove: bookmarks, completion: { (newBookmarks, responseIq) in
            if let newBookmarks = newBookmarks {
                DDLogInfo("New bookmarks \(newBookmarks)")
            } else {
                DDLogWarn("Failed to remove bookmarks \(bookmarks)")
            }
        })
    }
}

