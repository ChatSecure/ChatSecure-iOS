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

public class OTRRoomOccupantsViewController: UIViewController {
    
    let tableView: UITableView
    let viewHandler: OTRYapViewHandler
    let roomKey: String
    static let CellIdentifier = "Cell"
    
    public init(databaseConnection:YapDatabaseConnection, roomKey:String) {
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.roomKey = roomKey
        viewHandler = OTRYapViewHandler(databaseConnection: databaseConnection)
        super.init(nibName: nil, bundle: nil)
        setupViewHandler()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    private func setupViewHandler() {
        viewHandler.delegate = self
        viewHandler.setup(DatabaseExtensionName.groupOccupantsViewName.name(), groups: [roomKey])
    }
    
    private func setupTableView() {
        self.view.addSubview(self.tableView)
        self.tableView.autoPinEdgesToSuperviewEdges()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: OTRRoomOccupantsViewController.CellIdentifier)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
}

extension OTRRoomOccupantsViewController: OTRYapViewHandlerDelegateProtocol {

    public func didSetupMappings(_ handler: OTRYapViewHandler) {
        self.tableView.reloadData()
    }
    
    public func didReceiveChanges(_ handler: OTRYapViewHandler, sectionChanges: [YapDatabaseViewSectionChange], rowChanges: [YapDatabaseViewRowChange]) {
        //TODO: pretty animations
        self.tableView.reloadData()
    }
}

extension OTRRoomOccupantsViewController: UITableViewDataSource {
    //Int and UInt issue https://github.com/yapstudios/YapDatabase/issues/116
    public func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = self.viewHandler.mappings?.numberOfSections() {
            return Int(sections)
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rows = self.viewHandler.mappings?.numberOfItems(inSection: UInt(section)) {
            return Int(rows)
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OTRRoomOccupantsViewController.CellIdentifier, for: indexPath)
        
        if let roomOccupant = self.viewHandler.object(indexPath) as? OTRXMPPRoomOccupant {
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
