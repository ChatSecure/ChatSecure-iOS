//
//  OTRLogViewController.swift
//  ChatSecure
//
//  Created by David Chiles on 1/6/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import PureLayout
import CocoaLumberjack
import OTRAssets

private class LogInfoCell: UITableViewCell {
    
    static let reuseIdentifier = "LogInfoCell"
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

private extension DDLogFileInfo {
    var fileURL: URL {
        return URL(fileURLWithPath: filePath)
    }
}

public class OTRLogListViewController: UIViewController {
    
    private var files: [DDLogFileInfo] = []
    private let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = MANAGE_DEBUG_LOGS_STRING()
        
        setupTableView()
        refreshFileList()
    }
    
    func setupTableView() {
        tableView.register(LogInfoCell.self, forCellReuseIdentifier: LogInfoCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        self.view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
    }
    
    func refreshFileList() {
        files = DDLogFileManagerDefault().sortedLogFileInfos ?? []
        tableView.reloadData()
    }
    
    func file(at indexPath: IndexPath) -> DDLogFileInfo? {
        return files[indexPath.row]
    }
    
    func removeFile(at indexPath: IndexPath) {
        files.remove(at: indexPath.row)
    }
}

extension OTRLogListViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let file = file(at: indexPath) else {
            return
        }
        let url = file.fileURL
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let action = UITableViewRowAction(style: .destructive, title: DELETE_STRING()) { (action, indexPath) in
            guard let file = self.file(at: indexPath) else {
                return
            }
            let url = file.fileURL
            
            do {
                try FileManager.default.removeItem(at: url)
                self.removeFile(at: indexPath)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } catch { }
        }
        return [action]
    }
}

extension OTRLogListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LogInfoCell.reuseIdentifier, for: indexPath);
        
        if let file = file(at: indexPath) {
            cell.textLabel?.text = DateFormatter.localizedString(from: file.modificationDate, dateStyle: .long, timeStyle: .long)
            let bytes = ByteCountFormatter.string(fromByteCount: Int64(file.fileSize), countStyle: .file)
            cell.detailTextLabel?.text = bytes
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
