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
    return DDLogFileManagerDefault().sortedLogFileInfos
}

class LogInfoCell: UITableViewCell {
    
    static let reuseIdentifier = "LogInfoCell"
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

open
class OTRLogListViewController: UIViewController {
    
    let files = getAllLogFiles()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Log List Viewer"
        
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.register(LogInfoCell.self, forCellReuseIdentifier: LogInfoCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
    }
}

extension OTRLogListViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.files?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LogInfoCell.reuseIdentifier, for: indexPath);
        
        if let info = self.files?[indexPath.row] {
            cell.textLabel?.text = info.fileName
            cell.detailTextLabel?.text = DateFormatter.localizedString(from: info.modificationDate, dateStyle: .long, timeStyle: .long)
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let info = self.files?[indexPath.row] else {
            return
        }
        let url = URL(fileURLWithPath: info.filePath)
        
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
    }
}
