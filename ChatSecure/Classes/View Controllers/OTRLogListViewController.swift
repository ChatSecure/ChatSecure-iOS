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

@objc public class LogManager: NSObject {
    
    private var fileLogger: DDFileLogger?
    private let fileManager = DDLogFileManagerDefault()
    
    @objc public static let shared = LogManager()
    
    /// Resets all logging functionality
    @objc public func setupLogging() {
        debugPrint("Resetting all loggers...")
        DDLog.removeAllLoggers()
        
        // only allow console log output for debug builds
        #if DEBUG
            debugPrint("Enabling TTY logger...")
            DDLog.add(DDTTYLogger.sharedInstance)
            DDLogVerbose("TTY logger enabled.")
        #endif
        
        // allow file-based debug logging if user has enabled it
        if fileLoggingEnabled, let fileLogger = DDFileLogger() {
            debugPrint("Enabling file logger...")
            // create a new log on every launch
            fileLogger.doNotReuseLogFiles = true
            DDLog.add(fileLogger)
            self.fileLogger = fileLogger
            DDLogVerbose("File logger enabled.")
        } else {
            self.fileLogger = nil
        }
    }
    
    @objc public var fileLoggingEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: kOTREnableDebugLoggingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kOTREnableDebugLoggingKey)
            UserDefaults.standard.synchronize()
            
            // Delete old logs when user disables
            if newValue == false {
                if let logsDirectory = fileManager?.logsDirectory {
                    do {
                        try FileManager.default.removeItem(atPath: logsDirectory)
                    } catch {
                        DDLogError("Error deleting log files! \(error)")
                    }
                } else {
                    DDLogError("Error deleting log files! Could not find logs directory.")
                }
            }
            setupLogging()
        }
    }
    
    public var allLogFiles: [DDLogFileInfo] {
        return fileManager?.sortedLogFileInfos ?? []
    }
}

private class LogInfoCell: UITableViewCell {
    
    static let reuseIdentifier = "LogInfoCell"
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        detailTextLabel?.numberOfLines = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = nil
        detailTextLabel?.text = nil
        accessoryView = nil
        accessoryType = .none
    }
}

private extension DDLogFileInfo {
    var fileURL: URL {
        return URL(fileURLWithPath: filePath)
    }
}

public class OTRLogListViewController: UIViewController {
    
    private enum TableSection: Int {
        case logSwitch
        case files
        
        static let all: [TableSection] = [.logSwitch, .files]
    }
    
    private let logManager = LogManager.shared
    private var files: [DDLogFileInfo] = []
    private let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    private var refreshTimer: Timer?
    
    // MARK: View Lifecycle
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = MANAGE_DEBUG_LOGS_STRING()
        
        setupTableView()
        refreshFileList(animated: false)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refreshTimerUpdate(_:)), userInfo: nil, repeats: true)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func setupTableView() {
        tableView.register(LogInfoCell.self, forCellReuseIdentifier: LogInfoCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
    }
    
    // MARK: UI Refresh
    
    func refreshFileList(animated: Bool) {
        // Don't refresh table while animating or weird things happen
        if tableView.isEditing {
            return
        }
        files = logManager.allLogFiles
        var animation = UITableViewRowAnimation.automatic
        if animated == false {
            animation = .none
        }
        tableView.reloadSections([TableSection.files.rawValue], with: animation)
    }
    
    @objc func refreshTimerUpdate(_ timer: Timer) {
        refreshFileList(animated: false)
    }
    
    // MARK: File Management

    func file(at indexPath: IndexPath) -> DDLogFileInfo? {
        return files[indexPath.row]
    }
    
    func removeFile(at indexPath: IndexPath) {
        files.remove(at: indexPath.row)
    }
    
    // MARK: UI Actions
    
    @objc func loggingSwitchValueChanged(_ sender: UISwitch) {
        logManager.fileLoggingEnabled = sender.isOn
        refreshFileList(animated: true)
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
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return TableSection.all.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableSection = TableSection(rawValue: section) else {
            return 0
        }
        switch tableSection {
        case .logSwitch:
            return 1
        case .files:
            return files.count
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LogInfoCell.reuseIdentifier, for: indexPath)
        guard let section = TableSection(rawValue: indexPath.section) else {
            return cell
        }
        
        switch section {
        case .logSwitch:
            cell.textLabel?.text = ENABLE_DEBUG_LOGGING_STRING()
            let toggleSwitch = UISwitch()
            toggleSwitch.isOn = logManager.fileLoggingEnabled
            toggleSwitch.addTarget(self, action: #selector(loggingSwitchValueChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggleSwitch
        case .files:
            guard let file = file(at: indexPath) else {
                break
            }
            cell.textLabel?.text = DateFormatter.localizedString(from: file.modificationDate, dateStyle: .long, timeStyle: .long)
            let bytes = ByteCountFormatter.string(fromByteCount: Int64(file.fileSize), countStyle: .file)
            cell.detailTextLabel?.text = bytes
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let tableSection = TableSection(rawValue: section),
            tableSection == .logSwitch else {
                return nil
        }
        return ENABLE_DEBUG_LOGGING_HELP_STRING()
    }
}
