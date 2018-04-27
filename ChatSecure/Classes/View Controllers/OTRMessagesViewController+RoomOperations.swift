//
//  OTRMessagesViewController+RoomOperations.swift
//  ChatSecureCore
//
//  Created by N-Pex on 2018-04-11.
//  Copyright © 2018 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets

extension OTRMessagesViewController {

    fileprivate func findJoinRoomView() -> JoinRoomView? {
        return self.view.subviews.first { view -> Bool in
            return view is JoinRoomView
        } as? JoinRoomView
    }

    @objc open func updateJoinRoomView() {
        var state:RoomUserState = .invited
        self.connections?.ui.read({ (transaction) in
            if let room = self.room(with: transaction) {
                state = room.roomUserState
            }
        })
        if state == .hasViewed {
            hideJoinRoomView(animated: false)
        } else {
            showJoinRoomView()
        }
    }
    
    open func hideJoinRoomView(animated:Bool) {
        if let joinRoomView = findJoinRoomView() {
            if animated {
            UIView.animate(withDuration: 0.5, animations: {
                joinRoomView.alpha = 0.0
            }, completion: { (success) in
                joinRoomView.removeFromSuperview()
            })
            } else {
                joinRoomView.removeFromSuperview()
            }
        }
    }
    
    open func showJoinRoomView() {
        var joinRoomView = findJoinRoomView()
        if joinRoomView == nil {
            joinRoomView = UINib(nibName: "JoinRoomView", bundle: OTRAssets.resourcesBundle).instantiate(withOwner: nil, options: nil)[0] as? JoinRoomView
        }
        if let joinRoomView = joinRoomView {
            var roomName = ""
            connections?.read.read({ (transaction) in
                if let room = self.room(with: transaction) {
                    roomName = room.subject ?? room.roomJID?.bare ?? ""
                }
            })
            joinRoomView.titleLabel.text = String(format: YOU_HAVE_BEEN_INVITED_TO_GROUP_STRING(), roomName)
            joinRoomView.acceptButtonCallback = {() -> Void in
                self.setRoomSeen()
                DispatchQueue.main.async {
                    self.hideJoinRoomView(animated: true)
                }
            }
            joinRoomView.declineButtonCallback = {() -> Void in
                var room:OTRXMPPRoom? = nil
                var xmpp:XMPPManager? = nil
                self.connections?.read.read({ (transaction) in
                    room = self.room(with: transaction)
                    if let room = room {
                        if let account = room.account(with: transaction) {
                            xmpp = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager
                        }
                    }
                })
                if let room = room, let roomJid = room.roomJID, let xmpp = xmpp {
                    xmpp.roomManager.leaveRoom(roomJid)
                    xmpp.roomManager.removeRoomsFromBookmarks([room])
                    self.leaveRoom()
                }
            }
            self.view.addSubview(joinRoomView)
            joinRoomView.autoPinEdgesToSuperviewEdges()
            joinRoomView.becomeFirstResponder()
        }
    }
    
    @objc open func setRoomSeen() {
        self.connections?.write.readWrite({ (transaction) in
            if let room = self.room(with: transaction) {
                room.roomUserState = .hasViewed
                room.save(with: transaction)
            }
        })
    }
    
    @objc open func leaveRoom() {
        var room:OTRXMPPRoom? = nil
        connections?.ui.read { (transaction) in
            room = self.room(with: transaction)
        }
        if let room = room {
            self.setThreadKey(nil, collection: nil)
            connections?.write.readWrite({ (transaction) in
                room.remove(with: transaction)
            })
        }
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: false)
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                navigationController.navigationController?.popViewController(animated: true)
            }
        }
    }
}
