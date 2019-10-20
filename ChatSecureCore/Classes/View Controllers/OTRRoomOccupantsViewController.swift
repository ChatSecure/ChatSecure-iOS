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

private struct CellIdentifier {
    /// Storyboard Cell Identifiers
    static let HeaderCellGroupName = StoryboardCellIdentifier.groupName.rawValue
    static let HeaderCellShare = StoryboardCellIdentifier.share.rawValue
    static let HeaderCellAddFriends = StoryboardCellIdentifier.addFriends.rawValue
    static let HeaderCellMute = StoryboardCellIdentifier.mute.rawValue
    static let HeaderCellMembers = StoryboardCellIdentifier.members.rawValue
    static let FooterCellLeave = StoryboardCellIdentifier.leave.rawValue
}


/// Cell identifiers only used in code
private enum DynamicCellIdentifier: String {
    case occupant = "occupant"
    case omemoToggle = "cellGroupOMEMOToggle"
    case omemoConfig = "cellGroupOMEMOConfig"
}

/// Cell identifiers from the OTRRoomOccupants.storyboard
private enum StoryboardCellIdentifier: String {
    case groupName = "cellGroupName"
    case share = "cellGroupShare"
    case addFriends = "cellGroupAddFriends"
    case mute = "cellGroupMute"
    case members = "cellGroupMembers"
    case leave = "cellGroupLeave"
}

private class GenericHeaderCell: UITableViewCell {
    static let cellHeight: CGFloat = 44
    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = nil
        accessoryView = nil
    }
}

private enum GroupName: String {
    case header = "UITableViewSectionHeader"
    case footer = "UITableViewSectionFooter"
}

private let GroupNameHeader = GroupName.header.rawValue
private let GroupNameFooter = GroupName.footer.rawValue

open class OTRRoomOccupantsViewController: UIViewController {
    @objc public weak var delegate:OTRRoomOccupantsViewControllerDelegate? = nil

    @IBOutlet open weak var tableView:UITableView!
    @IBOutlet weak var largeAvatarView:UIImageView!
   
    let disabledCellAlphaValue:CGFloat = 0.5

    // For matching navigation bar and avatar
    var navigationBarShadow:UIImage?
    var navigationBarBackground:UIImage?
    var topBounceView:UIView?

    open var viewHandler:OTRYapViewHandler?
    
    open var roomUniqueId: String?
    var notificationToken:NSObjectProtocol? = nil
    
    /// opens implicit db transaction
    private var room: OTRXMPPRoom? {
        return connections?.ui.fetch { self.room($0) }
    }
    
    private func room(_ transaction: YapDatabaseReadTransaction) -> OTRXMPPRoom? {
        guard let roomUniqueId = self.roomUniqueId else {
            return nil
        }
        return OTRXMPPRoom.fetchObject(withUniqueID: roomUniqueId, transaction: transaction)
    }
    
    open var headerRows:[String] = []
    open var footerRows:[String] = []
    
    /// for reads only
    fileprivate let readConnection = OTRDatabaseManager.shared.uiConnection
    /// for reads and writes
    private let connection = OTRDatabaseManager.shared.writeConnection
    private let connections = OTRDatabaseManager.shared.connections
    /// When loading lists we don't want to update on every single change,
    /// so use this flag to ignore changes until everything is fetched.
    private var ignoreChanges = false
    open var crownImage:UIImage?
    
    
    @objc public init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(nibName: nil, bundle: nil)
        setupViewHandler(databaseConnection: databaseConnection, roomKey: roomKey)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc public func setupViewHandler(databaseConnection:YapDatabaseConnection, roomKey:String) {
        self.roomUniqueId = roomKey
        guard let room = self.room else {
            return
        }
        self.fetchMembersList(room: room)
        viewHandler = OTRYapViewHandler(databaseConnection: databaseConnection)
        if let viewHandler = self.viewHandler {
            viewHandler.delegate = self
            viewHandler.setup(DatabaseExtensionName.groupOccupantsViewName.name(), groups: [GroupName.header.rawValue, roomKey, GroupName.footer.rawValue])
        }
        
        
    }
    
    deinit {
        if let token = self.notificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        headerRows = [
            CellIdentifier.HeaderCellGroupName,
            CellIdentifier.HeaderCellAddFriends,
            CellIdentifier.HeaderCellMute,
            CellIdentifier.HeaderCellMembers
        ]
        
        if OTRSettingsManager.allowGroupOMEMO {
            headerRows.insert(DynamicCellIdentifier.omemoToggle.rawValue, at: 1)
            headerRows.insert(DynamicCellIdentifier.omemoConfig.rawValue, at: 2)
        }
        
        footerRows = [
            CellIdentifier.FooterCellLeave
        ]
        
        if let room = self.room {
            let seed = room.avatarSeed
            let image = OTRGroupAvatarGenerator.avatarImage(withSeed: seed, width: Int(largeAvatarView.frame.width), height: Int(largeAvatarView.frame.height))
            largeAvatarView.image = image
        }
        
        self.crownImage = UIImage(named: "crown", in: OTRAssets.resourcesBundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)

        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(OTRBuddyInfoCheckableCell.self, forCellReuseIdentifier: DynamicCellIdentifier.occupant.rawValue)
        self.tableView.register(GenericHeaderCell.self, forCellReuseIdentifier: DynamicCellIdentifier.omemoConfig.rawValue)
        self.tableView.register(GenericHeaderCell.self, forCellReuseIdentifier: DynamicCellIdentifier.omemoToggle.rawValue)
        
        self.tableView.reloadData()
        self.updateUIBasedOnOwnRole()
        
        self.notificationToken = NotificationCenter.default.addObserver(forName: NSNotification.Name.YapDatabaseModified, object: OTRDatabaseManager.shared.database, queue: OperationQueue.main) {[weak self] (notification) -> Void in
            self?.yapDatabaseModified(notification)
        }
    }

    func yapDatabaseModified(_ notification:Notification) {
        guard let connection = self.connections?.ui, let roomUniqueId = self.roomUniqueId else { return }
        if connection.hasChange(forKey: roomUniqueId, inCollection: OTRXMPPRoom.collection, in: [notification]) {
            // Subject has changed, update cell
            refreshSubjectCell()
        }
    }
    
    open func ownOccupant() -> OTRXMPPRoomOccupant? {
        guard let room = self.room, let accountId = room.accountUniqueId, let roomJid = room.roomJID, let ownJid = room.ourJID, let connection = self.connection else { return nil }
        var occupant:OTRXMPPRoomOccupant? = nil
        connection.read({ (transaction) in
           occupant = OTRXMPPRoomOccupant.occupant(jid: ownJid, realJID: ownJid, roomJID: roomJid, accountId: accountId, createIfNeeded: false, transaction: transaction)
        })
        return occupant
    }
    
    func updateUIBasedOnOwnRole() {
        var canInviteOthers = false
        if let ownOccupant = ownOccupant() {
            canInviteOthers = ownOccupant.canInviteOthers()
        }

        if !canInviteOthers, let idx = headerRows.firstIndex(of: CellIdentifier.HeaderCellAddFriends) {
            headerRows.remove(at: idx)
        } else if canInviteOthers, !headerRows.contains(CellIdentifier.HeaderCellAddFriends) {
            headerRows.insert(CellIdentifier.HeaderCellAddFriends, at: headerRows.firstIndex(of: CellIdentifier.HeaderCellMute) ?? 1)
        }
        
        // Update the header section
        if let idx = self.viewHandler?.mappings?.section(forGroup: GroupName.header.rawValue) {
            let set = IndexSet(integer: Int(idx))
            tableView.reloadSections(set, with: .none)
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
    
    private func refreshNotificationSwitch(_ notificationsSwitch: UISwitch, room: OTRXMPPRoom, animated: Bool) {
        let notificationsEnabled = !room.isMuted
        notificationsSwitch.setOn(notificationsEnabled, animated: animated)
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
    
    private func refreshSubjectCell() {
        if let section = self.viewHandler?.mappings?.section(forGroup: GroupName.header.rawValue), let row = self.headerRows.firstIndex(of: CellIdentifier.HeaderCellGroupName) {
            self.tableView.reloadRows(at: [IndexPath(row: row, section: Int(section))], with: .none)
        }
    }
    
    open func createHeaderCell(type:String, at indexPath: IndexPath) -> UITableViewCell {
        var _cell: UITableViewCell?
        if DynamicCellIdentifier(rawValue: type) != nil {
            _cell = tableView.dequeueReusableCell(withIdentifier: type, for: indexPath)
        } else {
            // storyboard cell
            _cell = tableView.dequeueReusableCell(withIdentifier: type)
        }
        guard let cell = _cell else { return UITableViewCell() }
        switch type {
        case CellIdentifier.HeaderCellGroupName:
            if let room = self.room {
                cell.textLabel?.text = room.subject
                cell.detailTextLabel?.text = "" // Do we have creation date?
            }
            
            var isOnline = false
            var canModifySubject = false
            if let ownOccupant = ownOccupant() {
                canModifySubject = ownOccupant.canModifySubject()
                isOnline = ownOccupant.role != .none
            }
            if !canModifySubject {
                cell.accessoryView = nil
                cell.isUserInteractionEnabled = false
            } else {
                let font:UIFont? = UIFont(name: "Material Icons", size: 24)
                let button = UIButton(type: .custom)
                if font != nil {
                    button.titleLabel?.font = font
                    button.setTitle("", for: .normal)
                }
                button.setTitleColor(UIColor.black, for: .normal)
                button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                button.addTarget(self, action: #selector(self.didPressEditGroupSubject(_:withEvent:)), for: .touchUpInside)
                button.titleLabel?.alpha = isOnline ? 1 :disabledCellAlphaValue
                cell.accessoryView = button
                cell.isUserInteractionEnabled = isOnline
            }
            cell.contentView.alpha = isOnline ? 1 : disabledCellAlphaValue
            cell.selectionStyle = .none
            break
        case CellIdentifier.HeaderCellAddFriends:
            var isOnline = false
            if let ownOccupant = ownOccupant() {
                isOnline = ownOccupant.role != .none
            }
            cell.isUserInteractionEnabled = isOnline
            cell.contentView.alpha = isOnline ? 1 : disabledCellAlphaValue
            break
        case CellIdentifier.HeaderCellMute:
            let muteswitch = UISwitch()
            if let room = self.room {
                refreshNotificationSwitch(muteswitch, room: room, animated:false)
            }
            muteswitch.addTarget(self, action: #selector(self.didChangeNotificationSwitch(_:)), for: .valueChanged)
            cell.accessoryView = muteswitch
            cell.isUserInteractionEnabled = true
            cell.selectionStyle = .none
            break
        case DynamicCellIdentifier.omemoToggle.rawValue:
            cell.textLabel?.text = OMEMO_GROUP_ENCRYPTION_STRING()
            cell.isUserInteractionEnabled = true
            cell.selectionStyle = .none
            let omemoSwitch = UISwitch()
            cell.accessoryView = omemoSwitch
            omemoSwitch.addTarget(self, action: #selector(self.didChangeGroupOMEMOSwitch(_:)), for: .valueChanged)
            if let room = self.room {
                refreshOMEMOGroupSwitch(omemoSwitch, room: room)
            } else {
                omemoSwitch.isOn = false
                omemoSwitch.isEnabled = false
            }
            break
        case DynamicCellIdentifier.omemoConfig.rawValue:
            cell.textLabel?.text = "OMEMO Configuration"
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        return cell
    }
    
    open func createFooterCell(type:String, at indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier:type) ?? UITableViewCell()
    }
    
    open func didSelectHeaderCell(type:String) {
        switch type {
        case CellIdentifier.HeaderCellAddFriends:
            addMoreFriends()
            break
        case DynamicCellIdentifier.omemoConfig.rawValue:
            var buddies: [OTRXMPPBuddy] = []
            connections?.ui.read {
                let room = self.room($0)
                buddies = room?.allBuddies($0) ?? []
            }
            let profile = GlobalTheme.shared.groupKeyManagementViewController(buddies: buddies)
            self.navigationController?.pushViewController(profile, animated: true)
        default: break
        }
    }
    
    open func didSelectFooterCell(type:String) {
        switch type {
        case CellIdentifier.FooterCellLeave:
            if let room = self.room,
                let roomJid = room.roomJID,
                let xmppRoomManager = self.xmppRoomManager(for: room) {
                //Leave room
                xmppRoomManager.leaveRoom(roomJid)
                xmppRoomManager.removeRoomsFromBookmarks([room])
                if let delegate = self.delegate {
                    delegate.didLeaveRoom(self)
                }
            }
            break
        default: break
        }
    }
    
    @objc func didChangeNotificationSwitch(_ sender: UISwitch) {
        let notificationSwitchIsOn = sender.isOn
        connections?.write.asyncReadWrite({ [weak self] (transaction) in
            guard let room = self?.room(transaction) else { return }
            if notificationSwitchIsOn {
                room.muteExpiration = Date.distantPast
            } else {
                room.muteExpiration = Date.distantFuture
            }
            room.save(with: transaction)
            }, completionBlock: { [weak self] in
                guard let room = self?.room else { return }
                self?.refreshNotificationSwitch(sender, room: room, animated: false)
        })
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
        let alert = UIAlertController(title: NSLocalizedString("Change room subject", comment: "Title for change room subject"), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: UIAlertAction.Style.default, handler: {(action: UIAlertAction!) in
            if let newSubject = alert.textFields?.first?.text {
                self.room?.subject = newSubject
                self.refreshSubjectCell()
                if let room = self.room, let xmppRoom = self.xmppRoom(for: room) {
                    xmppRoom.changeSubject(newSubject)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: UIAlertAction.Style.cancel, handler: nil))
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
    
    open func grantPrivileges(_ occupant:OTRXMPPRoomOccupant, affiliation:RoomOccupantAffiliation) {
        guard let room = self.room,
            let xmppRoom = self.xmppRoom(for: room),
            let occupantRealJid = occupant.realJID
            else { return }
        xmppRoom.editPrivileges([XMPPRoom.item(withAffiliation: affiliation.stringValue, jid: occupantRealJid)])
    }
    
    open func revokeMembership(_ occupant:OTRXMPPRoomOccupant) {
        guard let room = self.room,
            let xmppRoom = self.xmppRoom(for: room),
            let occupantRealJid = occupant.realJID
            else { return }
        xmppRoom.editPrivileges([XMPPRoom.item(withAffiliation: RoomOccupantAffiliation.none.stringValue, jid: occupantRealJid)])
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
    
    fileprivate func fetchMembersList(room: OTRXMPPRoom) {
        guard let xmppRoom = xmppRoom(for: room) else {
            return
        }
        ignoreChanges = true
        xmppRoomManager(for: room)?.fetchListsFor(room: xmppRoom, callback: {
            self.ignoreChanges = false
            self.tableView?.reloadData()
            self.updateUIBasedOnOwnRole()
            self.view.setNeedsLayout()
        })
    }
}

// MARK: - OTRYapViewHandlerDelegateProtocol
extension OTRRoomOccupantsViewController: OTRYapViewHandlerDelegateProtocol {

    public func didSetupMappings(_ handler: OTRYapViewHandler) {
        self.tableView?.reloadData()
    }
    
    public func didReceiveChanges(_ handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        guard !ignoreChanges else {return}
        //TODO: pretty animations
        self.tableView?.reloadData()
        self.updateUIBasedOnOwnRole()
        self.view.setNeedsLayout()
    }
}

// MARK: - UITableViewDataSource
extension OTRRoomOccupantsViewController: UITableViewDataSource {
    //Int and UInt issue https://github.com/yapstudios/YapDatabase/issues/116
    public func numberOfSections(in tableView: UITableView) -> Int {
        return Int(self.viewHandler?.mappings?.numberOfSections() ?? 0)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let group = self.viewHandler?.mappings?.group(forSection: UInt(section))
        
        if group == GroupNameHeader {
            return headerRows.count
        } else if group == GroupNameFooter {
            return footerRows.count
        }
        return Int(self.viewHandler?.mappings?.numberOfItems(inSection: UInt(section)) ?? 0)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = self.viewHandler?.mappings?.group(forSection: UInt(indexPath.section))
        if group == GroupNameHeader {
            return createHeaderCell(type: headerRows[indexPath.row], at: indexPath)
        } else if group == GroupNameFooter {
            return createFooterCell(type: footerRows[indexPath.row], at: indexPath)
        }
        
        if indexPath.section == 0 {
            let cell = createHeaderCell(type: CellIdentifier.HeaderCellMembers, at: indexPath)
            return cell
        }
        let cell:OTRBuddyInfoCheckableCell = tableView.dequeueReusableCell(withIdentifier: DynamicCellIdentifier.occupant.rawValue, for: indexPath) as! OTRBuddyInfoCheckableCell
        cell.setCheckImage(image: self.crownImage)
        var buddy:OTRXMPPBuddy? = nil
        var accountObject:OTRXMPPAccount? = nil
        guard let roomOccupant = self.viewHandler?.object(indexPath) as? OTRXMPPRoomOccupant,
            let room = self.room,
            let account = room.accountUniqueId 
            else {
                DDLogError("Could not configure RoomOccupant cell!")
                return cell
        }
        readConnection?.read({ (transaction) in
            buddy = roomOccupant.buddy(with: transaction)
            accountObject = OTRXMPPAccount.fetchObject(withUniqueID: account, transaction: transaction)
        })
        var isYou = false
        if let accountJid = accountObject?.bareJID?.bare,
            roomOccupant.realJID?.bare == accountJid {
            isYou = true
        }
        if let buddy = buddy {
            // Avoid showing ourselves as "pending approval"
            if isYou {
                buddy.pendingApproval = false
            }
            cell.setThread(buddy, account: nil)
            cell.accessoryView = cell.infoButton
            cell.infoAction = { [weak self] (cell, sender) in
                let profile = GlobalTheme.shared.groupKeyManagementViewController(buddies: [buddy])
                self?.navigationController?.pushViewController(profile, animated: true)
            }
        } else if let jid = roomOccupant.realJID ?? roomOccupant.jid {
            // Create temporary buddy for anonymous room members
            let buddy = OTRXMPPBuddy(jid: jid, accountId: account)
            if let occupantNickname = jid.resource {
                buddy.username = occupantNickname
            }
            buddy.trustLevel = .untrusted
            var status = OTRThreadStatus.offline
            if let jid = roomOccupant.jid,
                OTRBuddyCache.shared.jidOnline(jid.full, in: room)  {
                status = .available
            }
            OTRBuddyCache.shared.setThreadStatus(status, for: buddy, resource: roomOccupant.jid?.bare)
            cell.setThread(buddy, account: nil)
            cell.accessoryView = nil
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
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - UITableViewDelegate
extension OTRRoomOccupantsViewController:UITableViewDelegate {
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let group = self.viewHandler?.mappings?.group(forSection: UInt(indexPath.section))
        if group == GroupNameHeader {
            return GenericHeaderCell.cellHeight
        } else if group == GroupNameFooter {
            return GenericHeaderCell.cellHeight
        }
        return OTRBuddyInfoCellHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let group = self.viewHandler?.mappings?.group(forSection: UInt(indexPath.section))
        if group == GroupNameHeader {
            return GenericHeaderCell.cellHeight
        } else if group == GroupNameFooter {
            return GenericHeaderCell.cellHeight
        }
        return OTRBuddyInfoCellHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let group = self.viewHandler?.mappings?.group(forSection: UInt(indexPath.section))
        if group == GroupNameHeader {
            didSelectHeaderCell(type: headerRows[indexPath.row])
            return
        } else if group == GroupNameFooter {
            didSelectFooterCell(type: footerRows[indexPath.row])
            return
        }
        if let roomOccupant = self.viewHandler?.object(indexPath) as? OTRXMPPRoomOccupant {
            if let ownOccupant = ownOccupant(), ownOccupant.role == .moderator {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                if ownOccupant.canGrantAdmin(roomOccupant) {
                    let promoteAction = UIAlertAction(title: GROUP_GRANT_ADMIN_STRING(), style: .default, handler: { (action) in
                        self.grantPrivileges(roomOccupant, affiliation: .admin)
                    })
                    alert.addAction(promoteAction)
                }
                let viewAction = UIAlertAction(title: VIEW_PROFILE_STRING(), style: .default, handler: { (action) in
                    self.viewOccupantInfo(roomOccupant)
                })
                alert.addAction(viewAction)
                if ownOccupant.canRevokeMembership(roomOccupant) {
                    let kickAction = UIAlertAction(title: GROUP_REVOKE_MEMBERSHIP_STRING(), style: .destructive, handler: { (action) in
                        self.revokeMembership(roomOccupant)
                    })
                    alert.addAction(kickAction)
                }
                
                if alert.actions.count == 1 {
                    viewOccupantInfo(roomOccupant)
                } else {
                    let cancelAction = UIAlertAction(title: CANCEL_STRING(), style: .cancel, handler: nil)
                    alert.addAction(cancelAction)
                    if let popoverController = alert.popoverPresentationController {
                        popoverController.sourceView = tableView
                        popoverController.sourceRect = CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: 0, height: 0)
                        popoverController.permittedArrowDirections = []
                    }
                    present(alert, animated: true, completion: nil)
                }
            } else {
                viewOccupantInfo(roomOccupant)
            }
        }
    }
}

// MARK: - OTRComposeGroupViewControllerDelegate
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
