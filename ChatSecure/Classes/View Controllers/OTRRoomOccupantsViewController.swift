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
    static let CellIdentifier = "Cell"
    
    static let HeaderCellGroupName = "cellGroupName"
    static let HeaderCellShare = "cellGroupShare"
    static let HeaderCellAddFriends = "cellGroupAddFriends"
    static let HeaderCellMute = "cellGroupMute"
    static let HeaderCellMembers = "cellGroupMembers"
    static let FooterCellLeave = "cellGroupLeave"

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
        
        self.headerRows.append(OTRRoomOccupantsViewController.HeaderCellGroupName)
        self.headerRows.append(OTRRoomOccupantsViewController.HeaderCellShare)
        self.headerRows.append(OTRRoomOccupantsViewController.HeaderCellAddFriends)
        self.headerRows.append(OTRRoomOccupantsViewController.HeaderCellMute)
        self.headerRows.append(OTRRoomOccupantsViewController.HeaderCellMembers)
        self.footerRows.append(OTRRoomOccupantsViewController.FooterCellLeave)
        
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
    
    open func createHeaderCell(indexPath:IndexPath, type:String) -> UITableViewCell {
        switch type {
        case OTRRoomOccupantsViewController.HeaderCellGroupName:
            let cell = tableView.dequeueReusableCell(withIdentifier: type, for: indexPath)
            if let room = self.room {
                cell.textLabel?.text = room.subject
                cell.detailTextLabel?.text = "" // Do we have creation date?
            }
            cell.selectionStyle = .none
            return cell
        default:
            return tableView.dequeueReusableCell(withIdentifier: type, for: indexPath)
        }
    }
    
    open func createFooterCell(indexPath:IndexPath, type:String) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: type, for: indexPath)
    }
    
    open func didSelectHeaderCell(indexPath:IndexPath, type:String) {
        print("Selected \(type)")
    }
    
    open func didSelectFooterCell(indexPath:IndexPath, type:String) {
        print("Selected \(type)")
    }
    
    open func heightForHeaderCell(indexPath:IndexPath, type:String) -> CGFloat {
        return 44
    }
    
    open func heightForFooterCell(indexPath:IndexPath, type:String) -> CGFloat {
        return 44
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
        if let sections = self.viewHandler?.mappings?.numberOfSections() {
            return 2 + Int(sections)
        }
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isHeaderSection(section: section) {
            return headerRows.count
        } else if isFooterSection(section: section) {
            return footerRows.count
        }
        if let rows = self.viewHandler?.mappings?.numberOfItems(inSection: UInt(section - 1)) {
            return Int(rows)
        }
        return 0
    }
    
    open func isHeaderSection(section:Int) -> Bool {
        return section == 0
    }
    
    open func isFooterSection(section:Int) -> Bool {
        if let sections = self.viewHandler?.mappings?.numberOfSections() {
            if (section == (Int(sections) + 1)) {
                return true
            }
            return false
        }
        return section == 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isHeaderSection(section: indexPath.section) {
            return createHeaderCell(indexPath: indexPath, type: headerRows[indexPath.row])
        } else if isFooterSection(section: indexPath.section) {
            return createFooterCell(indexPath: indexPath, type: footerRows[indexPath.row])
        }
        let adjustedIndexPath = IndexPath(row: indexPath.row, section: indexPath.section - 1)
        let cell:OTRBuddyInfoCell = tableView.dequeueReusableCell(withIdentifier: OTRRoomOccupantsViewController.CellIdentifier, for: indexPath) as! OTRBuddyInfoCell
        var buddy:OTRXMPPBuddy? = nil
        if let roomOccupant = self.viewHandler?.object(adjustedIndexPath) as? OTRXMPPRoomOccupant, let room = self.room, let jid = roomOccupant.realJID ?? roomOccupant.jid, let account = room.accountUniqueId {
            OTRDatabaseManager.shared.readOnlyDatabaseConnection?.read({ (transaction) in
                    buddy = OTRXMPPBuddy.fetch(withUsername: jid, withAccountUniqueId: account, transaction: transaction)
            })
            if let buddy = buddy {
                cell.setThread(buddy, account: nil)
            }
        }
        cell.selectionStyle = .none
        return cell
    }
}

extension OTRRoomOccupantsViewController:UITableViewDelegate {
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if isHeaderSection(section: indexPath.section) {
            return heightForHeaderCell(indexPath:indexPath, type:headerRows[indexPath.row])
        } else if isFooterSection(section: indexPath.section) {
            return heightForFooterCell(indexPath:indexPath, type:footerRows[indexPath.row])
        }
        return OTRBuddyInfoCellHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isHeaderSection(section: indexPath.section) {
            return heightForHeaderCell(indexPath:indexPath, type:headerRows[indexPath.row])
        } else if isFooterSection(section: indexPath.section) {
            return heightForFooterCell(indexPath:indexPath, type:footerRows[indexPath.row])
        }
        return OTRBuddyInfoCellHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if isHeaderSection(section: indexPath.section) {
            didSelectHeaderCell(indexPath:indexPath, type:headerRows[indexPath.row])
        } else if isFooterSection(section: indexPath.section) {
            didSelectFooterCell(indexPath:indexPath, type:footerRows[indexPath.row])
        }
    }
    
}
