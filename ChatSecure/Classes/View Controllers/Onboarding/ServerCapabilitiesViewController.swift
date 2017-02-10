//
//  ServerCapabilitiesViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/9/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import XMPPFramework

public class ServerCapabilitiesViewController: UITableViewController, OTRServerCapabilitiesDelegate {
    
    /// You must set this before showing view
    public weak var serverCapabilitiesModule: OTRServerCapabilities?
    private let CellIdentifier = "CellIdentifier"
    
    private lazy var capabilities: [ServerCapabilityInfo] = {
        return ServerCapabilityInfo.allCapabilities()
    }()
    
    // MARK: User Interaction
    
    @objc private func doneButtonPressed(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: View Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(doneButtonPressed(_:)))
        navigationItem.rightBarButtonItem = doneButton
    }
    
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard let caps = serverCapabilitiesModule else { return }
        capabilities = markAvailable(capabilities, serverCapabilitiesModule: caps)
        caps.addDelegate(self, delegateQueue: dispatch_get_main_queue())
        tableView.reloadData()
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if let caps = serverCapabilitiesModule {
            caps.removeDelegate(self)
        }
    }
    
    // MARK: UITableViewDataSource
    
    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return capabilities.count
    }
    
    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath)
        let cellInfo = capabilities[indexPath.row]
        var text = "❔"
        switch cellInfo.status {
            case .Available:
                text = "✅"
                break
            case .Unavailable:
                text = "❌"
                break
            default:
                text = "❔"
        }
        text = text + " " + cellInfo.title
        cell.textLabel?.text = text
        return cell
    }
    
    // MARK: OTRServerCapabilitiesDelegate
    
    @objc public func serverCapabilities(sender: OTRServerCapabilities, didDiscoverAllCapabilities allCapabilities: [XMPPJID : DDXMLElement]) {
        guard let caps = serverCapabilitiesModule else { return }
        capabilities = markAvailable(capabilities, serverCapabilitiesModule: caps)
        tableView.reloadData()
    }
    
    // MARK: Utility
    
    private func markAvailable(capabilities: [ServerCapabilityInfo], serverCapabilitiesModule: OTRServerCapabilities) -> [ServerCapabilityInfo] {
        guard let allCaps = serverCapabilitiesModule.allCapabilities, let features = serverCapabilitiesModule.streamFeatures else {
            return capabilities
        }
        let allFeatures = OTRServerCapabilities.allFeaturesForCapabilities(allCaps, streamFeatures: features)
        var newCaps: [ServerCapabilityInfo] = []
        for var capInfo in capabilities {
            capInfo = capInfo.copy() as! ServerCapabilityInfo
            for feature in allFeatures {
                if feature.containsString(capInfo.xmlns) {
                    capInfo.status = .Available
                    break
                }
            }
            // if its not found, mark it unavailable
            if capInfo.status != .Available {
                capInfo.status = .Unavailable
            }
            newCaps.append(capInfo)
        }
        return newCaps
    }
}
