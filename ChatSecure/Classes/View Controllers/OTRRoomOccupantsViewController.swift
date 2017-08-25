//
//  OTRRoomOccupantsViewController.swift
//  ChatSecure
//
//  Created by David Chiles on 10/28/15.
//  Copyright © 2015 Chris Ballinger. All rights reserved.
//

import Foundation
import UIKit
import PureLayout

open class OTRRoomOccupantsViewController: UIViewController {
    
    @IBOutlet open weak var tableView:UITableView!
    @IBOutlet weak var largeAvatarView:UIImageView!
   
    // For matching navigation bar and avatar
    var navigationBarShadow:UIImage?
    var navigationBarBackground:UIImage?
    var topBounceView:UIView?
    
    open var viewHandler:OTRYapViewHandler?
    open var room:OTRXMPPRoom?
    open var headerRows:[String] = []
    open var footerRows:[String] = []
    fileprivate let readConnection = OTRDatabaseManager.shared.readOnlyDatabaseConnection
    
    static let CellIdentifier = "Cell"
    
    static let HeaderCellGroupName = "cellGroupName"
    static let HeaderCellShare = "cellGroupShare"
    static let HeaderCellAddFriends = "cellGroupAddFriends"
    static let HeaderCellMute = "cellGroupMute"
    static let HeaderCellUnmute = "cellGroupUnmute"
    static let HeaderCellMembers = "cellGroupMembers"
    static let FooterCellLeave = "cellGroupLeave"

    open var tableHeaderView:OTRVerticalStackView?
    open var tableFooterView:OTRVerticalStackView?
    
    public init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(nibName: nil, bundle: nil)
        setupViewHandler(databaseConnection: databaseConnection, roomKey: roomKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public func setupViewHandler(databaseConnection:YapDatabaseConnection, roomKey:String) {
        databaseConnection.read({ (transaction) in
            self.room = OTRXMPPRoom.fetchObject(withUniqueID: roomKey, transaction: transaction)
        })
        viewHandler = OTRYapViewHandler(databaseConnection: databaseConnection)
        if let viewHandler = self.viewHandler {
            viewHandler.delegate = self
            viewHandler.setup(DatabaseExtensionName.groupOccupantsViewName.name(), groups: [roomKey])
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        tableHeaderView = OTRVerticalStackView()
        tableFooterView = OTRVerticalStackView()
        
        let headerCells = [
            OTRRoomOccupantsViewController.HeaderCellGroupName,
            OTRRoomOccupantsViewController.HeaderCellAddFriends,
            OTRRoomOccupantsViewController.HeaderCellMute,
            OTRRoomOccupantsViewController.HeaderCellUnmute,
            OTRRoomOccupantsViewController.HeaderCellMembers
        ]
        
        let footerCells = [
            OTRRoomOccupantsViewController.FooterCellLeave
        ]

        for name in headerCells {
            let cell = createHeaderCell(type: name)
            tableHeaderView?.addStackedSubview(cell, identifier: name, gravity: .middle, height: 44, callback: { 
                self.didSelectHeaderCell(type: name)
            })
        }
        for name in footerCells {
            let cell = createFooterCell(type: name)
            tableFooterView?.addStackedSubview(cell, identifier: name, gravity: .middle, height: 44, callback: {
                self.didSelectFooterCell(type: name)
            })
        }
        
        // Add the avatar view topmost
        tableHeaderView?.addStackedSubview(largeAvatarView, identifier: "avatar", gravity: .top)
        
        self.tableView.tableHeaderView = self.tableHeaderView
        self.tableView.tableFooterView = self.tableFooterView
        updateMuteUnmuteCell()
        
        if let room = self.room {
            let seed = XMPPJID(string: room.jid).user ?? room.uniqueId
            let image = OTRGroupAvatarGenerator.avatarImage(withSeed: seed, width: Int(largeAvatarView.frame.width), height: Int(largeAvatarView.frame.height))
            largeAvatarView.image = image
        }
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(OTRBuddyInfoCell.self, forCellReuseIdentifier: OTRRoomOccupantsViewController.CellIdentifier)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.tableView {
            // Adjust the frame of the overscroll view
            if let topBounceView = self.topBounceView {
                let frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: self.tableView.contentOffset.y)
                topBounceView.frame = frame
            }
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Store shadow and background, so we can restore them
        self.navigationBarShadow = self.navigationController?.navigationBar.shadowImage
        self.navigationBarBackground = self.navigationController?.navigationBar.backgroundImage(for: .default)
        
        // Make the navigation bar the same color as the top color of the avatar image
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        if let room = self.room {
            let seed = XMPPJID(string: room.jid).user ?? room.uniqueId
            let avatarTopColor = UIColor(cgColor: OTRGroupAvatarGenerator.avatarTopColor(withSeed: seed))
            self.navigationController?.navigationBar.barTintColor = avatarTopColor
            
            // Create a view for the bounce background, with same color as the topmost
            // avatar color.
            if self.topBounceView == nil {
                self.topBounceView = UIView()
                if let view = self.topBounceView {
                    view.backgroundColor = avatarTopColor
                    self.tableView.addSubview(view)
                }
            }
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Restore navigation bar
        self.navigationController?.navigationBar.barTintColor = UINavigationBar.appearance().barTintColor
        self.navigationController?.navigationBar.shadowImage = self.navigationBarShadow
        self.navigationController?.navigationBar.setBackgroundImage(self.navigationBarBackground, for: .default)
    }
    
    private func updateMuteUnmuteCell() {
        var muted = false
        if let room = self.room {
            muted = room.isMuted
        }
        self.tableHeaderView?.setView(OTRRoomOccupantsViewController.HeaderCellMute, hidden: muted)
        self.tableHeaderView?.setView(OTRRoomOccupantsViewController.HeaderCellUnmute, hidden: !muted)
    }
    
    open func createHeaderCell(type:String) -> UITableViewCell {
        var cell:UITableViewCell?
        switch type {
        case OTRRoomOccupantsViewController.HeaderCellGroupName:
            cell = tableView.dequeueReusableCell(withIdentifier: type)
            if let room = self.room {
                cell?.textLabel?.text = room.subject
                cell?.detailTextLabel?.text = "" // Do we have creation date?
            }
            cell?.selectionStyle = .none
            break
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: type)
            break
        }
        return cell ?? UITableViewCell()
    }
    
    open func createFooterCell(type:String) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: type) ?? UITableViewCell()
    }
    
    open func didSelectHeaderCell(type:String) {
        switch type {
        case OTRRoomOccupantsViewController.HeaderCellMute, OTRRoomOccupantsViewController.HeaderCellUnmute:
            if let room = self.room {
                if room.isMuted {
                    room.muteExpiration = nil
                } else {
                    room.muteExpiration = Date.distantFuture
                }
                OTRDatabaseManager.shared.readWriteDatabaseConnection?.asyncReadWrite({ (transaction) in
                    room.save(with: transaction)
                })
                updateMuteUnmuteCell()
            }
            break
        default: break
        }
    }
    
    open func didSelectFooterCell(type:String) {
    }
}

extension OTRRoomOccupantsViewController {
    
    /** Do not call this within a yap transaction! */
    fileprivate func xmppRoom() -> XMPPRoom? {
        var xmpp: OTRXMPPManager? = nil
        self.readConnection?.read { transaction in
            if let account = self.room?.account(with: transaction) {
                xmpp = OTRProtocolManager.shared.protocol(for: account) as? OTRXMPPManager
            }
        }
        guard let room = self.room,
            let jid = room.jid,
            let roomJid = XMPPJID(string: jid),
            let xmppRoom = xmpp?.roomManager.room(for: roomJid)
            else { return nil }
        return xmppRoom
    }
    
    fileprivate func fetchMembersList(_ sender: Any) {
        guard let xmppRoom = xmppRoom() else { return }
        xmppRoom.fetchMembersList()
    }
}

extension OTRRoomOccupantsViewController: OTRYapViewHandlerDelegateProtocol {

    public func didSetupMappings(_ handler: OTRYapViewHandler) {
        self.tableView?.reloadData()
    }
    
    public func didReceiveChanges(_ handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        //TODO: pretty animations
        self.tableView?.reloadData()
    }
}

extension OTRRoomOccupantsViewController: UITableViewDataSource {
    //Int and UInt issue https://github.com/yapstudios/YapDatabase/issues/116
    public func numberOfSections(in tableView: UITableView) -> Int {
        return Int(self.viewHandler?.mappings?.numberOfSections() ?? 0)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(self.viewHandler?.mappings?.numberOfItems(inSection: UInt(section)) ?? 0)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:OTRBuddyInfoCell = tableView.dequeueReusableCell(withIdentifier: OTRRoomOccupantsViewController.CellIdentifier, for: indexPath) as! OTRBuddyInfoCell
        var buddy:OTRXMPPBuddy? = nil
        if let roomOccupant = self.viewHandler?.object(indexPath) as? OTRXMPPRoomOccupant, let room = self.room, let jid = roomOccupant.realJID ?? roomOccupant.jid, let account = room.accountUniqueId {
            OTRDatabaseManager.shared.readOnlyDatabaseConnection?.read({ (transaction) in
                    buddy = OTRXMPPBuddy.fetch(withUsername: jid, withAccountUniqueId: account, transaction: transaction)
            })
            if let buddy = buddy {
                cell.setThread(buddy, account: nil)
            } else if let roomJid = roomOccupant.jid,
                let jidStr = roomOccupant.realJID,
                let displayName = roomOccupant.roomName {
                // Create temporary buddy
                // Do not save here or it will auto-trust random people
                let uniqueId = roomJid + account
                let buddy = OTRXMPPBuddy(uniqueId: uniqueId)
                buddy.username = jidStr
                buddy.displayName = displayName
                var status: OTRThreadStatus = .available
                if !roomOccupant.available {
                    status = .offline
                }
                OTRBuddyCache.shared.setThreadStatus(status, for: buddy, resource: nil)
                cell.setThread(buddy, account: nil)
                DDLogInfo("No trusted buddy found for occupant \(roomOccupant)")
            }
        }
        cell.selectionStyle = .none
        return cell
    }
}

extension OTRRoomOccupantsViewController:UITableViewDelegate {
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return OTRBuddyInfoCellHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return OTRBuddyInfoCellHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
