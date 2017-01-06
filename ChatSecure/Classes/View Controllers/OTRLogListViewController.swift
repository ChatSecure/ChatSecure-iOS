//
//  OTRLogViewController.swift
//  ChatSecure
//
//  Created by David Chiles on 1/6/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import PureLayout

func getAllLogFiles() -> [DDLogFileInfo]? {
    return DDLogFileManagerDefault().sortedLogFileInfos() as? [DDLogFileInfo]
}

class LogInfoCell: UITableViewCell {
    
    static let reuseIdentifier = "LogInfoCell"
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

public
class OTRLogListViewController: UIViewController {
    
    let files = getAllLogFiles()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Log List Viewer"
        
        let tableView = UITableView(frame: CGRectZero, style: .Plain)
        tableView.registerClass(LogInfoCell.self, forCellReuseIdentifier: LogInfoCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
    }
}

extension OTRLogListViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files?.count ?? 0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(LogInfoCell.reuseIdentifier, forIndexPath: indexPath);
        
        if let info = self.files?[indexPath.row] {
            cell.textLabel?.text = info.fileName
            cell.detailTextLabel?.text = NSDateFormatter.localizedStringFromDate(info.modificationDate, dateStyle: .LongStyle, timeStyle: .LongStyle)
        }
        
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard let info = self.files?[indexPath.row] else {
            return
        }
        let url = NSURL(fileURLWithPath: info.filePath)
        
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
}
