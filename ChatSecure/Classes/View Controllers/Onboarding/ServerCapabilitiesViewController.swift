//
//  ServerCapabilitiesViewController.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/9/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit
import XMPPFramework

private enum Availability {
    case Unknown
    case Available
    case Unavailable
}

private struct CapabilityInfo {
    var availability: Availability = .Unknown
    let title: String
    let description: String
    let xml: String // used to match against caps xml
    
    init(title: String, description: String, xml: String) {
        self.title = title
        self.description = description
        self.xml = xml
    }
}

public class ServerCapabilitiesViewController: UITableViewController, OTRServerCapabilitiesDelegate {
    
    /// You must set this before showing view
    public weak var serverCapabilitiesModule: OTRServerCapabilities?
    private let CellIdentifier = "CellIdentifier"
    
    private lazy var capabilities: [CapabilityInfo] = {
        var capInfo: [CapabilityInfo] = []
        // TODO: load this from JSON or Plist
        // TODO: use localizable keys
        capInfo.append(CapabilityInfo(
            title: "Stream Management",
            description: "XEP-0198: Provides better experience during temporary disconnections.",
            xml: "urn:xmpp:sm"))
        capInfo.append(CapabilityInfo(
            title: "Push",
            description: "XEP-0357: Provides push messaging support.",
            xml: "urn:xmpp:push"))
        return capInfo
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
        switch cellInfo.availability {
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
    
    private func markAvailable(capabilities: [CapabilityInfo], serverCapabilitiesModule: OTRServerCapabilities) -> [CapabilityInfo] {
        guard let allCaps = serverCapabilitiesModule.allCapabilities, let features = serverCapabilitiesModule.streamFeatures else {
            return capabilities
        }
        let allFeatures = OTRServerCapabilities.allFeaturesForCapabilities(allCaps, streamFeatures: features)
        var newCaps: [CapabilityInfo] = []
        for var capInfo in capabilities {
            for feature in allFeatures {
                if feature.containsString(capInfo.xml) {
                    capInfo.availability = .Available
                    break
                }
            }
            // if its not found, mark it unavailable
            if capInfo.availability != .Available {
                capInfo.availability = .Unavailable
            }
            newCaps.append(capInfo)
        }
        return newCaps
    }
}
