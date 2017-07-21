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
    
    @IBOutlet weak var tableView:UITableView!
    open var viewHandler:OTRYapViewHandler?
    open var roomKey:String?
    
    public init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        super.init(nibName: nil, bundle: nil)
        setupViewHandler(databaseConnection: databaseConnection, roomKey: roomKey)
    }

    public func setupViewHandler(databaseConnection:YapDatabaseConnection, roomKey:String) {
        self.roomKey = roomKey
        viewHandler = OTRYapViewHandler(databaseConnection: databaseConnection)
        viewHandler?.delegate = self
        viewHandler?.setup(DatabaseExtensionName.groupOccupantsViewName.name(), groups: [roomKey])
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup Table View
        if (self.tableView == nil) {
            self.tableView = UITableView(frame: CGRect.zero, style: .plain)
            self.view.addSubview(self.tableView)
            self.tableView.autoPinEdgesToSuperviewEdges()
        }
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
}

extension OTRRoomOccupantsViewController:OTRYapViewHandlerDelegateProtocol {

    public func didSetupMappings(_ handler: OTRYapViewHandler) {
        self.tableView?.reloadData()
    }
    
    public func didReceiveChanges(_ handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        //TODO: pretty animations
        self.tableView?.reloadData()
    }
}

extension OTRRoomOccupantsViewController:UITableViewDataSource {
    //Int and UInt issue https://github.com/yapstudios/YapDatabase/issues/116
    public func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = self.viewHandler?.mappings?.numberOfSections() {
            return Int(sections)
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rows = self.viewHandler?.mappings?.numberOfItems(inSection: UInt(section)) {
            return Int(rows)
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let roomOccupant = self.viewHandler?.object(indexPath) as? OTRXMPPRoomOccupant {
            cell.textLabel?.text = roomOccupant.realJID ?? roomOccupant.jid
        } else {
            cell.detailTextLabel?.text = ""
            cell.textLabel?.text = ""
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
}

extension OTRRoomOccupantsViewController:UITableViewDelegate {
    
}
