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
import BButton
import OTRAssets

@objc public protocol OTRRoomOccupantsViewControllerDelegate {
    func didLeaveRoom(_ roomOccupantsViewController: OTRRoomOccupantsViewController) -> Void
    func didArchiveRoom(_ roomOccupantsViewController: OTRRoomOccupantsViewController) -> Void
}

private class CellIdentifier {
    static let Generic = "Cell"
    static let HeaderCellGroupName = "cellGroupName"
    static let HeaderCellShare = "cellGroupShare"
    static let HeaderCellAddFriends = "cellGroupAddFriends"
    static let HeaderCellMute = "cellGroupMute"
    static let HeaderCellMembers = "cellGroupMembers"
    static let HeaderCellGroupOMEMO = "cellGroupOMEMO"
    static let FooterCellLeave = "cellGroupLeave"
}

open class OTRRoomOccupantsViewController: UIViewController {
 
    @objc public weak var delegate:OTRRoomOccupantsViewControllerDelegate? = nil

    @IBOutlet open weak var tableView:UITableView!
    @IBOutlet weak var largeAvatarView:UIImageView!
   
    // For matching navigation bar and avatar
    var navigationBarShadow:UIImage?
    var navigationBarBackground:UIImage?
    var topBounceView:UIView?

    open var viewHandler:OTRYapViewHandler?
    
    open var roomUniqueId: String?
    
    /// opens implicit db transaction
    open var room:OTRXMPPRoom? {
        guard let roomUniqueId = self.roomUniqueId else {
            return nil
        }
        var _room: OTRXMPPRoom?
        readConnection?.read({ (transaction) in
            _room = OTRXMPPRoom.fetchObject(withUniqueID: roomUniqueId, transaction: transaction)
        })
        return _room
    }
    
    open var headerRows:[String] = []
    open var footerRows:[String] = []
    /// for reads only
    fileprivate let readConnection = OTRDatabaseManager.shared.readOnlyDatabaseConnection
    /// for reads and writes
    private let connection = OTRDatabaseManager.shared.readWriteDatabaseConnection
    open var crownImage:UIImage?
    


    open var tableHeaderView:OTRVerticalStackView?
    open var tableFooterView:OTRVerticalStackView?
    
    @objc public init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(nibName: nil, bundle: nil)
        setupViewHandler(databaseConnection: databaseConnection, roomKey: roomKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc public func setupViewHandler(databaseConnection:YapDatabaseConnection, roomKey:String) {
        self.roomUniqueId = roomKey
        guard let _ = self.room else {
            return
        }
        self.fetchMembersList()
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
        
        var headerCells = [
            CellIdentifier.HeaderCellGroupName,
            CellIdentifier.HeaderCellAddFriends,
            CellIdentifier.HeaderCellMute,
            CellIdentifier.HeaderCellMembers
        ]
        
        if OTRSettingsManager.allowGroupOMEMO {
            headerCells.insert(CellIdentifier.HeaderCellGroupOMEMO, at: 1)
        }
        
        let footerCells = [
            CellIdentifier.FooterCellLeave
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
        
        if let room = self.room {
            let seed = room.avatarSeed
            let image = OTRGroupAvatarGenerator.avatarImage(withSeed: seed, width: Int(largeAvatarView.frame.width), height: Int(largeAvatarView.frame.height))
            largeAvatarView.image = image
        }
        
        self.crownImage = UIImage(named: "crown", in: OTRAssets.resourcesBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(OTRBuddyInfoCheckableCell.self, forCellReuseIdentifier: CellIdentifier.Generic)
        
        self.updateUIBasedOnOwnRole()
    }
    
    func updateUIBasedOnOwnRole() {
        var canInviteOthers = false
        var canModifySubject = false
        
        if let room = self.room, let accountId = room.accountUniqueId, let roomJidStr = room.jid, let roomJid = XMPPJID(string: roomJidStr), let ownJidStr = room.ownJID, let ownJid = XMPPJID(string: ownJidStr), let connection = self.connection {
                connection.read({ (transaction) in
                    if let ownOccupant = OTRXMPPRoomOccupant.occupant(jid: ownJid, realJID: ownJid, roomJID: roomJid, accountId: accountId, createIfNeeded: false, transaction: transaction) {
                        canInviteOthers = ownOccupant.role.canInviteOthers()
                        canModifySubject = ownOccupant.role.canModifySubject()
                    }
            })
        }
        
        tableHeaderView?.setView(CellIdentifier.HeaderCellAddFriends, hidden: !canInviteOthers)
        
        if let subjectCell = tableHeaderView?.viewWithIdentifier(identifier: CellIdentifier.HeaderCellGroupName) as? UITableViewCell {
            if !canModifySubject {
                subjectCell.accessoryView = nil
                subjectCell.isUserInteractionEnabled = false
            } else {
                let font:UIFont? = UIFont(name: "Material Icons", size: 24)
                let button = UIButton(type: UIButtonType.custom)
                if font != nil {
                    button.titleLabel?.font = font
                    button.setTitle("", for: UIControlState())
                }
                button.setTitleColor(UIColor.black, for: UIControlState())
                button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                button.addTarget(self, action: #selector(self.didPressEditGroupSubject(_:withEvent:)), for: UIControlEvents.touchUpInside)
                subjectCell.accessoryView = button
                subjectCell.isUserInteractionEnabled = true
            }
        }
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
            let seed = room.avatarSeed
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
    
    private func refreshNotificationSwitch(_ notificationsSwitch: UISwitch, room: OTRXMPPRoom) {
        let notificationsEnabled = !room.isMuted
        notificationsSwitch.setOn(notificationsEnabled, animated: true)
    }
    
    private func refreshOMEMOGroupSwitch(_ omemoSwitch: UISwitch, room: OTRXMPPRoom) {
        var bestAvailable: OTRMessageTransportSecurity = .invalid
        var preference: RoomSecurity = .best
        readConnection?.read({ (transaction) in
            bestAvailable = room.bestTransportSecurity(with: transaction)
            preference = room.preferredSecurity
        })
        if bestAvailable == .OMEMO {
            omemoSwitch.isEnabled = true
            if preference == .plaintext {
                omemoSwitch.isOn = false
            } else {
                omemoSwitch.isOn = true
            }
        } else {
            omemoSwitch.isEnabled = false
            omemoSwitch.isOn = false
        }
    }
    
    open func createHeaderCell(type:String) -> UITableViewCell {
        var cell:UITableViewCell?
        switch type {
        case CellIdentifier.HeaderCellGroupName:
            cell = tableView.dequeueReusableCell(withIdentifier: type)
            if let room = self.room {
                cell?.textLabel?.text = room.subject
                cell?.detailTextLabel?.text = "" // Do we have creation date?
            }
            cell?.selectionStyle = .none
            break
        case CellIdentifier.HeaderCellMute:
            cell = tableView.dequeueReusableCell(withIdentifier: type)
            let muteswitch = UISwitch()
            if let room = self.room {
                refreshNotificationSwitch(muteswitch, room: room)
            }
            muteswitch.addTarget(self, action: #selector(self.didChangeNotificationSwitch(_:)), for: .valueChanged)
            cell?.accessoryView = muteswitch
            cell?.isUserInteractionEnabled = true
            cell?.selectionStyle = .none
            break
        case CellIdentifier.HeaderCellGroupOMEMO:
            cell = tableView.dequeueReusableCell(withIdentifier: type)
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: type)
            }
            cell?.textLabel?.text = "OMEMO"
            cell?.isUserInteractionEnabled = true
            cell?.selectionStyle = .none
            let omemoSwitch = UISwitch()
            cell?.accessoryView = omemoSwitch
            omemoSwitch.addTarget(self, action: #selector(self.didChangeGroupOMEMOSwitch(_:)), for: .valueChanged)
            if let room = self.room {
                refreshOMEMOGroupSwitch(omemoSwitch, room: room)
            } else {
                omemoSwitch.isOn = false
                omemoSwitch.isEnabled = false
            }
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
        case CellIdentifier.HeaderCellAddFriends:
            addMoreFriends()
            break
        default: break
        }
    }
    
    open func didSelectFooterCell(type:String) {
        switch type {
        case CellIdentifier.FooterCellLeave:
            if let room = self.room, let roomJidStr = room.jid, let roomJid = XMPPJID(string: roomJidStr), let xmppRoomManager = self.xmppRoomManager(for: room) {
                //Leave room
                xmppRoomManager.leaveRoom(roomJid)
                if let delegate = self.delegate {
                    delegate.didLeaveRoom(self)
                }
            }
            break
        default: break
        }
    }
    @objc func didChangeNotificationSwitch(_ sender: UIControl!) {
        guard let notificationSwitch = sender as? UISwitch,
        let room = self.room?.copyAsSelf() else {
            return
        }
        if notificationSwitch.isOn {
            room.muteExpiration = Date.distantFuture
        } else {
            room.muteExpiration = nil
        }
        connection?.readWrite({ (transaction) in
            room.save(with: transaction)
        })
        refreshNotificationSwitch(notificationSwitch, room: room)
    }
    
    @objc func didChangeGroupOMEMOSwitch(_ sender: UISwitch) {
        guard let room = self.room?.copyAsSelf() else {
            return
        }
        var preference = RoomSecurity.best
        if sender.isOn {
            preference = RoomSecurity.omemo
        } else {
            preference = RoomSecurity.plaintext
        }
        room.preferredSecurity = preference
        connection?.readWrite({ (transaction) in
            room.save(with: transaction)
        })
        refreshOMEMOGroupSwitch(sender, room: room)
    }
    
    @objc func didPressEditGroupSubject(_ sender: UIControl!, withEvent: UIEvent!) {
        let alert = UIAlertController(title: NSLocalizedString("Change room subject", comment: "Title for change room subject"), message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: UIAlertActionStyle.default, handler: {(action: UIAlertAction!) in
            if let newSubject = alert.textFields?.first?.text {
                if let cell = self.tableHeaderView?.viewWithIdentifier(identifier: CellIdentifier.HeaderCellGroupName) as? UITableViewCell {
                    cell.textLabel?.text = newSubject
                }
                if let room = self.room, let xmppRoom = self.xmppRoom(for: room) {
                    xmppRoom.changeSubject(newSubject)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: UIAlertActionStyle.cancel, handler: nil))
        alert.addTextField(configurationHandler: {(textField: UITextField!) in
            textField.placeholder = self.room?.subject
            textField.isSecureTextEntry = false
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    private func addMoreFriends() {
        let storyboard = UIStoryboard(name: "OTRComposeGroup", bundle: OTRAssets.resourcesBundle)
        if let vc = storyboard.instantiateInitialViewController() as? OTRComposeGroupViewController {
            vc.delegate = self
            vc.setExistingRoomOccupants(viewHandler: self.viewHandler, room: self.room)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    open func viewOccupantInfo(_ occupant:OTRXMPPRoomOccupant) {
        // Show profile view?
    }
}

extension OTRRoomOccupantsViewController {
    
    /** Do not call this within a yap transaction! */
    fileprivate func xmppRoom(for room: OTRXMPPRoom) -> XMPPRoom? {
        guard let roomManager = xmppRoomManager(for: room),
            let roomJid = room.roomJID,
            let xmppRoom = roomManager.room(for: roomJid)
            else { return nil }
        return xmppRoom
    }
    
    fileprivate func xmppRoomManager(for room: OTRXMPPRoom) -> OTRXMPPRoomManager? {
        var xmpp: XMPPManager? = nil
        self.readConnection?.read { transaction in
            if let account = room.account(with: transaction) {
                xmpp = OTRProtocolManager.shared.protocol(for: account) as? XMPPManager
            }
        }
        return xmpp?.roomManager
    }
    
    fileprivate func fetchMembersList() {
        guard let room = self.room,
            let xmppRoom = xmppRoom(for: room) else {
            return
        }
        xmppRoom.fetchMembersList()
        xmppRoom.fetchAdminsList()
        xmppRoom.fetchOwnersList()
        xmppRoom.fetchModeratorsList()
    }
}

extension OTRRoomOccupantsViewController: OTRYapViewHandlerDelegateProtocol {

    public func didSetupMappings(_ handler: OTRYapViewHandler) {
        self.tableView?.reloadData()
    }
    
    public func didReceiveChanges(_ handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        //TODO: pretty animations
        self.tableView?.reloadData()
        self.updateUIBasedOnOwnRole()
        self.view.setNeedsLayout()
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
        let cell:OTRBuddyInfoCheckableCell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.Generic, for: indexPath) as! OTRBuddyInfoCheckableCell
        cell.setCheckImage(image: self.crownImage)
        var buddy:OTRXMPPBuddy? = nil
        var accountObject:OTRXMPPAccount? = nil
        if let roomOccupant = self.viewHandler?.object(indexPath) as? OTRXMPPRoomOccupant, let room = self.room, let account = room.accountUniqueId {
            readConnection?.read({ (transaction) in
                buddy = roomOccupant.buddy(with: transaction)
                accountObject = OTRXMPPAccount.fetchObject(withUniqueID: account, transaction: transaction)
            })
            var isYou = false
            if let accountJid = accountObject?.bareJID?.bare, roomOccupant.realJID == accountJid {
                isYou = true
            }

            if let buddy = buddy {
                cell.setThread(buddy, account: nil)
            } else if let roomJid = room.jid {
                // Create temporary buddy
                // Do not save here or it will auto-trust random people
                let uniqueId = roomJid + account
                let buddy = OTRXMPPBuddy(uniqueId: uniqueId)
                buddy.username = roomOccupant.realJID ?? roomOccupant.jids.first?.full ?? ""
                buddy.displayName = roomOccupant.roomName ?? buddy.username
                var status: OTRThreadStatus = .available
                
                //Any of the occupants jids online?
                if !roomOccupant.jids.contains(where: { (jid) -> Bool in
                    return OTRBuddyCache.shared.jidOnline(jid.full, in: room)
                }) {
                    status = .offline
                }
                OTRBuddyCache.shared.setThreadStatus(status, for: buddy, resource: nil)
                cell.setThread(buddy, account: nil)
            }
            
            if isYou {
                if let accountObject = accountObject {
                    cell.avatarImageView.image = accountObject.avatarImage()
                }
                cell.nameLabel.text?.append(" (" + GROUP_INFO_YOU() + ")")
            }
            
            if roomOccupant.affiliation == .owner || roomOccupant.affiliation == .admin {
                cell.setChecked(checked: true)
            } else {
                cell.setChecked(checked: false)
            }
            if roomOccupant.role == .none {
                // Not present in the room
                cell.nameLabel.textColor = UIColor.lightGray
                cell.identifierLabel.textColor = UIColor.lightGray
                cell.accountLabel.textColor = UIColor.lightGray
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
        if let roomOccupant = self.viewHandler?.object(indexPath) as? OTRXMPPRoomOccupant {
            viewOccupantInfo(roomOccupant)
        }
    }
}

extension OTRRoomOccupantsViewController: OTRComposeGroupViewControllerDelegate {
    
    public func groupSelectionCancelled(_ composeViewController: OTRComposeGroupViewController) {
    }
    
    public func groupBuddiesSelected(_ composeViewController: OTRComposeGroupViewController, buddyUniqueIds: [String], groupName: String) {
        // Add them to the room
        if let room = self.room,
            let xmppRoom = self.xmppRoom(for: room),
            let xmppRoomManager = self.xmppRoomManager(for: room) {
            xmppRoomManager.inviteBuddies(buddyUniqueIds, to: xmppRoom)
        }
        self.navigationController?.popToViewController(self, animated: true)
    }
}
