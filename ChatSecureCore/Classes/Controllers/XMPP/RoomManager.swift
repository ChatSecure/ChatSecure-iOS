//
//  RoomManager.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 11/17/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

extension OTRXMPPRoomManager {
    
    @objc public func join(room: OTRXMPPRoom) {
        guard let roomJID = room.roomJID else { return }
        joinRoom(roomJID, withNickname: nil, subject: room.subject, password: room.roomPassword)
    }
    
    private func roomForBookmark(_ bookmark: XMPPBookmark) -> OTRXMPPRoom? {
        guard let conference = bookmark as? XMPPConferenceBookmark,
            let accountId = self.accountId else {
                return nil
        }
        let room = OTRXMPPRoom()!
        room.accountUniqueId = accountId
        room.roomJID = conference.jid
        room.subject = conference.bookmarkName
        room.roomPassword = conference.password
        room.roomUserState = .hasViewed
        return room
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
        self.databaseConnection.asyncReadWrite({ (transaction) in
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
    
    @objc public func fetchHistory(for xmppRoom: XMPPRoom) {
        self.databaseConnection.asyncRead { (transaction) in
            guard let room = OTRXMPPRoom.fetch(xmppRoom: xmppRoom, transaction: transaction) else {
                    return
            }
            // if we've never fetched MAM before, try to fetch the last week
            // otherwise fetch since the last time we fetched
            var dateToFetch = room.lastHistoryFetch
            if dateToFetch == nil {
                let currentDate = Date()
                var dateComponents = DateComponents()
                dateComponents.day = -7
                let lastWeek = Calendar.current.date(byAdding: dateComponents, to: currentDate)
                dateToFetch = lastWeek
            }
            self.archiving.fetchHistory(archiveJID: xmppRoom.roomJID, userJID: nil, since: dateToFetch)
        }
    }
    
    @objc public func beginUpdateAffiliations(inRoom xmppRoom: XMPPRoom) {
        self.databaseConnection.asyncReadWrite({ (transaction) in
            guard let room = OTRXMPPRoom.fetch(xmppRoom: xmppRoom, transaction: transaction) else {
                return
            }
            for occupant in room.allOccupants(transaction) {
                switch occupant.affiliation {
                case .admin, .member, .owner:
                    occupant.affiliation = .transient
                    occupant.save(with: transaction)
                default: break
                }
            }
        })
    }

    @objc public func endUpdateAffiliations(inRoom xmppRoom: XMPPRoom) {
        self.databaseConnection.asyncReadWrite({ (transaction) in
            guard let room = OTRXMPPRoom.fetch(xmppRoom: xmppRoom, transaction: transaction) else {
                return
            }
            for occupant in room.allOccupants(transaction) {
                if occupant.affiliation == .transient {
                    occupant.remove(with: transaction)
                }
            }
        })
    }
    
    fileprivate class FetchListDelegate: NSObject, XMPPRoomDelegate {
        let group:DispatchGroup
        fileprivate init(group:DispatchGroup) {
            self.group = group
        }
        
        func xmppRoom(_ sender: XMPPRoom, didFetchMembersList items: [Any]) {
            group.leave()
        }
        
        func xmppRoom(_ sender: XMPPRoom, didNotFetchMembersList iqError: XMPPIQ) {
            group.leave()
        }
        
        func xmppRoom(_ sender: XMPPRoom, didFetchAdminsList items: [Any]) {
            group.leave()
        }
        
        func xmppRoom(_ sender: XMPPRoom, didNotFetchAdminsList iqError: XMPPIQ) {
            group.leave()
        }
        
        func xmppRoom(_ sender: XMPPRoom, didFetchOwnersList items: [Any]) {
            group.leave()
        }
        
        func xmppRoom(_ sender: XMPPRoom, didNotFetchOwnersList iqError: XMPPIQ) {
            group.leave()
        }
    }
    
    @objc public func fetchListsFor(room xmppRoom: XMPPRoom, callback:(() -> Void)?) {
        DispatchQueue.global().async {
            let group = DispatchGroup()
            let delegate = FetchListDelegate(group: group)
            xmppRoom.addDelegate(delegate, delegateQueue: DispatchQueue.global())
            group.enter()
            xmppRoom.fetchMembersList()
            group.enter()
            xmppRoom.fetchAdminsList()
            group.enter()
            xmppRoom.fetchOwnersList()
            group.notify(queue: .main, execute: {
                xmppRoom.removeDelegate(delegate)
                if let callback = callback {
                    callback()
                }
            })
        }
    }
}

