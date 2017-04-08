//
//  FileTransferManager.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 3/28/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework
import CocoaLumberjack
import OTRKit

public enum FileTransferManagerError: Error {
    case unknown
    case noServers
    case exceedsMaxSize
    case fileNotFound
}

public class FileTransferManager: NSObject, OTRServerCapabilitiesDelegate {

    let httpFileUpload: XMPPHTTPFileUpload
    let serverCapabilities: OTRServerCapabilities
    let connection: YapDatabaseConnection
    let internalQueue = DispatchQueue(label: "FileTransferManager Queue")
    let callbackQueue = DispatchQueue.main
    let urlSession: URLSession
    private var servers: [HTTPServer] = []
    
    public var canUploadFiles: Bool {
        return self.servers.first != nil
    }
    
    deinit {
        httpFileUpload.removeDelegate(self)
        serverCapabilities.removeDelegate(self)
    }
    
    public init(connection: YapDatabaseConnection,
                serverCapabilities: OTRServerCapabilities,
                sessionConfiguration: URLSessionConfiguration?) {
        self.serverCapabilities = serverCapabilities
        self.httpFileUpload = XMPPHTTPFileUpload()
        self.connection = connection
        self.urlSession = URLSession(configuration: sessionConfiguration ?? URLSessionConfiguration.ephemeral)
        super.init()
        httpFileUpload.activate(serverCapabilities.xmppStream)
        httpFileUpload.addDelegate(self, delegateQueue: DispatchQueue.main)
        serverCapabilities.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.refreshCapabilities()
    }
    
    // MARK: - Public Methods
    
    /// This will fetch capabilities and setup XMPP transfer module if needed
    public func refreshCapabilities() {
        guard let allCapabilities = serverCapabilities.allCapabilities else {
            serverCapabilities.fetchAllCapabilities()
            return
        }
        servers = serversFromCapabilities(capabilities: allCapabilities)
        serverCapabilities.fetchAllCapabilities()
    }

    public func upload(mediaItem: OTRMediaItem,
                       prefetchedData: Data?,
                       completion: @escaping (_ url: URL?, _ error: Error?) -> ()) {
        internalQueue.async {
            if let data = prefetchedData {
                self.upload(data: data, filename: mediaItem.filename, contentType: mediaItem.mimeType, completion: completion)
            } else {
                var url: URL? = nil
                self.connection.read({ (transaction) in
                    url = mediaItem.mediaServerURL(with: transaction)
                })
                if let url = url {
                    self.upload(file: url, completion: completion)
                } else {
                    let error = FileTransferManagerError.fileNotFound
                    DDLogError("Upload filed: File not found \(error)")
                    self.callbackQueue.async {
                        completion(nil, error)
                    }
                }
            }
        }
    }
    
    /// Currently just a wrapper around sendData
    public func upload(file: URL,
                     completion: @escaping (_ url: URL?, _ error: Error?) -> ()) {
        internalQueue.async {
            do {
                let data = try Data(contentsOf: file)
                let mimeType = OTRKitGetMimeTypeForExtension(file.pathExtension)
                self.upload(data: data, filename: file.lastPathComponent, contentType: mimeType, completion: completion)
            } catch let error {
                DDLogError("Error sending file URL \(file): \(error)")
            }
        }
        
    }
    
    public func upload(data: Data,
                 filename: String,
                 contentType: String,
                 completion: @escaping (_ url: URL?, _ error: Error?) -> ()) {
        internalQueue.async {
            guard let service = self.servers.first else {
                DDLogWarn("No HTTP upload servers available")
                self.callbackQueue.async {
                    completion(nil, FileTransferManagerError.noServers)
                }
                return
            }
            if UInt(data.count) > service.maxSize {
                DDLogError("HTTP Upload exceeds max size \(data.count) > \(service.maxSize)")
                self.callbackQueue.async {
                    completion(nil, FileTransferManagerError.exceedsMaxSize)
                }
                return
            }
            self.httpFileUpload.requestSlot(fromService: service.jid, filename: filename, size: UInt(data.count), contentType: contentType, completion: { (slot: XMPPSlot?, iq: XMPPIQ?, error: Error?) in
                guard let slot = slot else {
                    if let error = error {
                        DDLogError("\(service) failed to assign upload slot: \(error)")
                        self.callbackQueue.async {
                            completion(nil, error)
                        }
                    }
                    return
                }
                let request = slot.putRequest
                let upload = self.urlSession.uploadTask(with: request, from: data, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
                    self.callbackQueue.async {
                        if let error = error {
                            completion(nil, error)
                        } else if let _ = response {
                            completion(slot.getURL, nil)
                        }
                    }
                })
                upload.resume()
            })
        }
    }
    
    public func send(videoURL: URL, buddy: OTRBuddy) {
        
    }
    
    public func send(audioURL: URL, buddy: OTRBuddy) {
        
    }
    
    public func send(image: UIImage, buddy: OTRBuddy) {
        internalQueue.async {
            let scaleFactor: CGFloat = 0.25;
            let newSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
            let scaledImage = UIImage.otr_image(with: image, scaledTo: newSize)
            let imageData = UIImageJPEGRepresentation(scaledImage, 0.5)
            let filename = "\(UUID().uuidString).jpg"
            let imageItem = OTRImageItem(filename: filename, size: newSize, mimeType: "image/jpeg", isIncoming: false)
            let message = OTROutgoingMessage()!
            var security: OTRMessageTransportSecurity = .invalid
            self.connection.read({ (transaction) in
                security = buddy.preferredTransportSecurity(with: transaction)
            })
            message.buddyUniqueId = buddy.uniqueId
            message.mediaItemUniqueId = imageItem.uniqueId
            message.messageSecurityInfo = OTRMessageEncryptionInfo(messageSecurity: security)
            self.connection.readWrite({ (transaction) in
                message.save(with: transaction)
                imageItem.save(with: transaction)
            })
            OTRMediaFileManager.sharedInstance().setData(imageData, for: imageItem, buddyUniqueId: buddy.uniqueId, completion: { (bytesWritten: Int, error: Error?) in
                self.connection.readWrite({ (transaction) in
                    imageItem.touchParentMessage(with: transaction)
                    if let error = error {
                        message.error = error
                        message.save(with: transaction)
                    }
                })
                self.upload(mediaItem: imageItem, prefetchedData: imageData, completion: { (_url: URL?, error: Error?) in
                    guard let url = _url else {
                        if let error = error {
                            DDLogError("Error uploading: \(error)")
                        }
                        self.connection.readWrite({ (transaction) in
                            message.error = error
                            message.save(with: transaction)
                        })
                        return
                    }
                    self.connection.readWrite({ (transaction) in
                        imageItem.transferProgress = 1.0
                        message.text = url.absoluteString
                        imageItem.save(with: transaction)
                        message.save(with: transaction)
                    })
                    self.queueOutgoingMessage(message: message)
                })
            }, completionQueue: self.internalQueue)
        }
        
    }
    
    private func queueOutgoingMessage(message: OTROutgoingMessage) {
        let sendAction = OTRYapMessageSendAction(messageKey: message.uniqueId, messageCollection: message.messageCollection(), buddyKey: message.buddyUniqueId, date: message.date)
        self.connection.readWrite { (transaction) in
            message.save(with: transaction)
            sendAction.save(with: transaction)
            if let buddy = message.threadOwner(with: transaction) as? OTRBuddy {
                buddy.lastMessageId = message.uniqueId
                buddy.save(with: transaction)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func serversFromCapabilities(capabilities: [XMPPJID : XMLElement]) -> [HTTPServer] {
        var servers: [HTTPServer] = []
        for (jid, element) in capabilities {
            let supported = element.supportsHTTPUpload()
            let maxSize = element.maxHTTPUploadSize()
            if supported && maxSize > 0 {
                let server = HTTPServer(jid: jid, maxSize: maxSize)
                servers.append(server)
            }
        }
        return servers
    }

    // MARK: - OTRServerCapabilitiesDelegate
    
    public func serverCapabilities(_ sender: OTRServerCapabilities, didDiscoverCapabilities capabilities: [XMPPJID : XMLElement]) {
        servers = serversFromCapabilities(capabilities: capabilities)
    }
}

fileprivate struct HTTPServer {
    /// service jid for upload service
    let jid: XMPPJID
    /// max upload size in bytes
    let maxSize: UInt
}

public extension XMLElement {
    
    // For use on a <query> element
    func supportsHTTPUpload() -> Bool {
        let features = self.elements(forName: "feature")
        var supported = false
        for feature in features {
            if let value = feature.attributeStringValue(forName: "var"), value == XMPPHTTPFileUploadNamespace  {
                supported = true
                break
            }
        }
        return supported
    }
    
    /// Returns 0 on failure, or max file size in bytes
    func maxHTTPUploadSize() -> UInt {
        var maxSize: UInt = 0
        guard let xes = self.elements(forXmlns: "jabber:x:data") as? [XMLElement] else { return 0 }
        
        for x in xes {
            let fields = x.elements(forName: "field")
            var correctXEP = false
            for field in fields {
                if let value = field.forName("value") {
                    if value.stringValue == XMPPHTTPFileUploadNamespace {
                        correctXEP = true
                    }
                    if let varMaxFileSize = field.attributeStringValue(forName: "var"), varMaxFileSize == "max-file-size" {
                        maxSize = value.stringValueAsNSUInteger()
                    }
                }
            }
            if correctXEP && maxSize > 0 {
                break
            }
        }
        
        return maxSize
    }
}
