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
import LumberjackConsole

@objc public class LogManager: NSObject {
    
    fileprivate var consoleLogger: PTEConsoleLogger?
    private var fileLogger: DDFileLogger?
    private let fileManager = DDLogFileManagerDefault()
    
    @objc public static let shared = LogManager()
    
    public override init() {
        super.init()
        // Disable file logging if it's disabled via branding flag
        // this will also delete any old log files
        if OTRBranding.allowDebugFileLogging == false {
            fileLoggingEnabled = false
        }
    }
    
    /// Resets all logging functionality
    @objc public func setupLogging() {
        debugPrint("Resetting all loggers...")
        DDLog.removeAllLoggers()
        
        // only allow console log output for debug builds
        #if DEBUG
            debugPrint("Enabling os_log logger...")
            DDLog.add(DDOSLogger.sharedInstance)
            DDLogVerbose("os_log logger enabled.")
        #endif
        
        // allow file-based debug logging if user has enabled it
        let fileLogger = DDFileLogger()
        if fileLoggingEnabled {
            debugPrint("Enabling file logger...")
            // create a new log on every launch
            fileLogger.doNotReuseLogFiles = true
            DDLog.add(fileLogger)
            self.fileLogger = fileLogger
            DDLogVerbose("File logger enabled.")
            
            let consoleLogger = PTEConsoleLogger()
            DDLog.add(consoleLogger)
            self.consoleLogger = consoleLogger
            DDLogVerbose("Console logger enabled.")
        } else {
            self.fileLogger = nil
            self.consoleLogger = nil
        }
    }
    
    /// setting to `false` will also delete any old log files
    /// and reset the debugger
    @objc public var fileLoggingEnabled: Bool {
        get {
            // Disable file logging if it's disabled via branding flag
            if OTRBranding.allowDebugFileLogging == false {
                return false
            }
            return UserDefaults.standard.bool(forKey: kOTREnableDebugLoggingKey)
        }
        set {
            var newValue = newValue
            // Disable file logging if it's disabled via branding flag
            if OTRBranding.allowDebugFileLogging == false {
                newValue = false
            }
            UserDefaults.standard.set(newValue, forKey: kOTREnableDebugLoggingKey)
            UserDefaults.standard.synchronize()
            
            // Delete old logs when user disables
            if newValue == false {
                let logsDirectory = fileManager.logsDirectory
                do {
                    try FileManager.default.removeItem(atPath: logsDirectory)
                } catch {
                    DDLogError("Error deleting log files! \(error)")
                }
            }
            setupLogging()
        }
    }
    
    public var allLogFiles: [DDLogFileInfo] {
        return fileManager.sortedLogFileInfos
    }
}

private class LogInfoCell: UITableViewCell {
    
    static let reuseIdentifier = "LogInfoCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        detailTextLabel?.numberOfLines = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textLabel?.text = nil
        textLabel?.font = nil
        detailTextLabel?.text = nil
        accessoryView = nil
        accessoryType = .none
        selectionStyle = .none
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
        case showConsole
        case files
        
        static let all: [TableSection] = [.logSwitch, .showConsole, .files]
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
        var animation = UITableView.RowAnimation.automatic
        if animated == false {
            animation = .none
        }
        tableView.reloadSections([TableSection.files.rawValue, TableSection.showConsole.rawValue], with: animation)
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
    
    func shareFile(at indexPath: IndexPath) {
        guard let file = file(at: indexPath) else {
            return
        }
        let url = file.fileURL
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func showConsole() {
        guard let storyboard = UIStoryboard.lumberjackConsole,
        let vc = storyboard.instantiateInitialViewController() as? PTEConsoleTableViewController else {
            return
        }
        vc.logger = logManager.consoleLogger
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension OTRLogListViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = TableSection(rawValue: indexPath.section) else {
            return
        }
        switch section {
        case .logSwitch:
            break
        case .showConsole:
            showConsole()
            tableView.deselectRow(at: indexPath, animated: true)
        case .files:
            shareFile(at: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: DELETE_STRING()) { (action, view, completion) in
            guard let file = self.file(at: indexPath) else {
                completion(false)
                return
            }
            let url = file.fileURL
            do {
                try FileManager.default.removeItem(at: url)
                self.removeFile(at: indexPath)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                completion(true)
            } catch {
                completion(false)
            }
        }
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
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
        case .showConsole:
            if logManager.fileLoggingEnabled {
                return 1
            } else {
                return 0
            }
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
            cell.selectionStyle = .none
        case .showConsole:
            cell.textLabel?.text = SHOW_CONSOLE_STRING()
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case .files:
            guard let file = file(at: indexPath) else {
                break
            }
            // bold the first entry because that's the active one
            if indexPath.row == 0 {
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            }
            cell.textLabel?.text = DateFormatter.localizedString(from: file.modificationDate, dateStyle: .long, timeStyle: .long)
            let bytes = ByteCountFormatter.string(fromByteCount: Int64(file.fileSize), countStyle: .file)
            cell.detailTextLabel?.text = bytes
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let tableSection = TableSection(rawValue: indexPath.section),
            tableSection == .files {
            return 60
        }
        return 50
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let tableSection = TableSection(rawValue: section),
            tableSection == .logSwitch {
                return ENABLE_DEBUG_LOGGING_HELP_STRING()
        }
        return nil
    }
}

private extension UIStoryboard {
    static var lumberjackConsole: UIStoryboard? {
        let bundle = Bundle(for: PTEConsoleLogger.self)
        let storyboard = UIStoryboard(name: "LumberjackConsole", bundle: bundle)
        return storyboard
    }
}
