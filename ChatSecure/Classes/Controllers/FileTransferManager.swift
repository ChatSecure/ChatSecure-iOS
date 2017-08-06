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
import Alamofire
import OTRAssets

extension UIImage {
    enum DataSize {
        case unlimited
        case maxBytes(UInt)
        var numBytes: UInt {
            switch self {
            case .unlimited:
                return UInt.max
            case .maxBytes(let limit):
                return limit
            }
        }
    }
     struct Quality {
        static let medium = Quality(initial: 0.65, decrementFactor: 0.65)
        static let high = Quality(initial: 0.75, decrementFactor: 0.75)
        
        /// This value cannot be > 1 or bad things will happen
        let initial: CGFloat
        /// Multiplied to reduce the initial value. This value cannot be > 1 or bad things will happen
        let decrementFactor: CGFloat
    }
    func jpegData(dataSize: DataSize,
                  resize: Quality = Quality.high,
                  jpeg: Quality = Quality.high,
                  maxTries: UInt = 10) -> Data? {
        let image = self
        var sizeInBytes: UInt = 0
        var scaleFactor: CGFloat = resize.initial
        var jpegQuality: CGFloat = jpeg.initial
        let qualityDecrement: CGFloat = jpeg.decrementFactor
        let scaleDecrement: CGFloat = resize.decrementFactor
        var scaledImageData: Data? = nil
        var newSize = CGSize.zero
        let maxTries = 10
        var numTries = 0
        let maxSize = dataSize.numBytes
        while (sizeInBytes == 0 || sizeInBytes > maxSize) &&
            numTries < maxTries {
                numTries = numTries + 1
                newSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
                let scaledImage = UIImage.otr_image(with: image, scaledTo: newSize)
                scaledImageData = UIImageJPEGRepresentation(scaledImage, jpegQuality)
                if let imageData = scaledImageData {
                    sizeInBytes = UInt(imageData.count)
                    scaleFactor = scaleFactor * scaleDecrement
                    jpegQuality = jpegQuality * qualityDecrement
                } else {
                    DDLogError("Could not make JPEG out of image!")
                    return nil
                }
        }
        return scaledImageData
    }
}

public enum FileTransferError: CustomNSError {
    case unknown
    case noServers
    case serverError
    case exceedsMaxSize
    case urlFormatting
    case fileNotFound
    case keyGenerationError
    case cryptoError
    case automaticDownloadsDisabled
    
    public var localizedDescription: String {
        switch self {
        case .unknown:
            return UNKNOWN_ERROR_STRING()
        case .noServers:
            return NO_HTTP_UPLOAD_SERVERS_STRING() + " " + PLEASE_CONTACT_SERVER_OP_STRING()
        case .serverError:
            return UNKNOWN_ERROR_STRING() + " " + PLEASE_CONTACT_SERVER_OP_STRING()
        case .exceedsMaxSize:
            return FILE_EXCEEDS_MAX_SIZE_STRING()
        case .urlFormatting:
            return COULD_NOT_PARSE_URL_STRING()
        case .fileNotFound:
            return FILE_NOT_FOUND_STRING()
        case .cryptoError, .keyGenerationError:
            return errSSLCryptoString()
        case .automaticDownloadsDisabled:
            return AUTOMATIC_DOWNLOADS_DISABLED_STRING()
        }
    }
}

public class FileTransferManager: NSObject, OTRServerCapabilitiesDelegate {

    let httpFileUpload: XMPPHTTPFileUpload
    let serverCapabilities: OTRServerCapabilities
    let connection: YapDatabaseConnection
    let internalQueue = DispatchQueue(label: "FileTransferManager Queue")
    let callbackQueue = DispatchQueue.main
    let sessionManager: SessionManager
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
                sessionConfiguration: URLSessionConfiguration) {
        self.serverCapabilities = serverCapabilities
        self.httpFileUpload = XMPPHTTPFileUpload()
        self.connection = connection
        self.sessionManager = Alamofire.SessionManager(configuration: sessionConfiguration)
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

    private func upload(mediaItem: OTRMediaItem,
                        shouldEncrypt: Bool,
                       prefetchedData: Data?,
                       completion: @escaping (_ url: URL?, _ error: Error?) -> ()) {
        internalQueue.async {
            if let data = prefetchedData {
                self.upload(media: mediaItem, data: data, shouldEncrypt: shouldEncrypt, filename: mediaItem.filename, contentType: mediaItem.mimeType, completion: completion)
            } else {
                var url: URL? = nil
                self.connection.read({ (transaction) in
                    url = mediaItem.mediaServerURL(with: transaction)
                })
                if let url = url {
                    self.upload(media: mediaItem, file: url, shouldEncrypt: shouldEncrypt, completion: completion)
                } else {
                    let error = FileTransferError.fileNotFound
                    DDLogError("Upload filed: File not found \(error)")
                    self.callbackQueue.async {
                        completion(nil, error)
                    }
                }
            }
        }
    }
    
    /// Currently just a wrapper around sendData
    private func upload(media: OTRMediaItem,
                        file: URL,
                        shouldEncrypt: Bool,
                     completion: @escaping (_ url: URL?, _ error: Error?) -> ()) {
        internalQueue.async {
            do {
                let data = try Data(contentsOf: file)
                let mimeType = OTRKitGetMimeTypeForExtension(file.pathExtension)
                self.upload(media: media, data: data, shouldEncrypt: shouldEncrypt, filename: file.lastPathComponent, contentType: mimeType, completion: completion)
            } catch let error {
                DDLogError("Error sending file URL \(file): \(error)")
            }
        }
        
    }
    
    private func upload(media: OTRMediaItem,
                        data: Data,
                        shouldEncrypt: Bool,
                 filename: String,
                 contentType: String,
                 completion: @escaping (_ url: URL?, _ error: Error?) -> ()) {
        internalQueue.async {
            guard let service = self.servers.first else {
                DDLogWarn("No HTTP upload servers available")
                self.callbackQueue.async {
                    completion(nil, FileTransferError.noServers)
                }
                return
            }
            if UInt(data.count) > service.maxSize {
                DDLogError("HTTP Upload exceeds max size \(data.count) > \(service.maxSize)")
                self.callbackQueue.async {
                    completion(nil, FileTransferError.exceedsMaxSize)
                }
                return
            }
            
            // TODO: Refactor to use streaming encryption
            var outData = data
            var outKeyIv: Data? = nil
            if shouldEncrypt {
                guard let key = OTRPasswordGenerator.randomData(withLength: 32), let iv = OTRPasswordGenerator.randomData(withLength: 16) else {
                    DDLogError("Could not generate key/iv")
                    self.callbackQueue.async {
                        completion(nil, FileTransferError.keyGenerationError)
                    }
                    return
                }
                outKeyIv = iv + key
                do {
                    let crypted = try OTRCryptoUtility.encryptAESGCMData(data, key: key, iv: iv)
                    outData = crypted.data + crypted.authTag
                } catch let error {
                    outData = Data()
                    DDLogError("Could not encrypt data for file transfer \(error)")
                    self.callbackQueue.async {
                        completion(nil, error)
                    }
                    return
                }
            }
            
            
            self.httpFileUpload.requestSlot(fromService: service.jid, filename: filename, size: UInt(outData.count), contentType: contentType, completion: { (slot: XMPPSlot?, iq: XMPPIQ?, error: Error?) in
                guard let slot = slot else {
                    let outError = error ?? FileTransferError.serverError
                    DDLogError("\(service) failed to assign upload slot: \(outError)")
                    self.callbackQueue.async {
                        completion(nil, outError)
                    }
                    return
                }
                self.sessionManager.upload(outData, to: slot.putURL, method: .put)
                    .validate()
                    .responseData(queue: self.callbackQueue) { response in
                        switch response.result {
                        case .success:
                            if let outKeyIv = outKeyIv {
                                // If there's a AES-GCM key, we gotta put it in the url
                                // and change the scheme to `aesgcm`
                                if var components = URLComponents(url: slot.getURL, resolvingAgainstBaseURL: true) {
                                    components.scheme = URLScheme.aesgcm.rawValue
                                    components.fragment = outKeyIv.hexString()
                                    if let outURL = components.url {
                                        completion(outURL, nil)
                                    } else {
                                        completion(nil, FileTransferError.urlFormatting)
                                    }
                                } else {
                                    completion(nil, FileTransferError.urlFormatting)
                                }
                            } else {
                                // The plaintext case
                                completion(slot.getURL, nil)
                            }
                        case .failure(let error):
                            completion(nil, error)
                            DDLogError("Upload error: \(error)")
                        }
                    }.uploadProgress(queue: self.internalQueue) { progress in
                        DDLogVerbose("Download progress \(progress.fractionCompleted)")
                        self.connection.asyncReadWrite { transaction in
                            if let media = media.refetch(with: transaction) {
                                media.transferProgress = Float(progress.fractionCompleted)
                                media.save(with: transaction)
                                media.touchParentMessage(with: transaction)
                            }
                        }
                }
            })
        }
    }
    
    public func send(videoURL url: URL, buddy: OTRBuddy) {
        internalQueue.async {
            self.send(url: url, buddy: buddy, type: .video)
        }
    }
    
    private enum MediaURLType {
        case audio
        case video
        //case image
    }
    
    private func send(url: URL, buddy: OTRBuddy, type: MediaURLType) {
        internalQueue.async {
            var item: OTRMediaItem? = nil
            switch type {
            case .audio:
                item = OTRAudioItem(audioURL: url, isIncoming: false)
            case .video:
                item = OTRVideoItem(videoURL: url, isIncoming: false)
            }
            guard let mediaItem = item else {
                DDLogError("No media item to share for URL: \(url)")
                return
            }
            
            let message = self.newOutgoingMessage(to: buddy, mediaItem: mediaItem)
            let newPath = OTRMediaFileManager.path(for: mediaItem, buddyUniqueId: buddy.uniqueId)
            self.connection.readWrite({ (transaction) in
                message.save(with: transaction)
                mediaItem.save(with: transaction)
            })
            OTRMediaFileManager.shared.copyData(fromFilePath: url.path, toEncryptedPath: newPath, completion: { (result, copyError: Error?) in
                var prefetchedData: Data? = nil
                if FileManager.default.fileExists(atPath: url.path) {
                    do {
                        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                        if let size = attributes[FileAttributeKey.size] as? NSNumber, size.uint64Value < 1024 * 1024 * 1 {
                            prefetchedData = try Data(contentsOf: url)
                        }
                    } catch let error {
                        DDLogError("Error prefetching data: \(error)")
                    }
                    do {
                        try FileManager.default.removeItem(atPath: url.path)
                    } catch let error {
                        DDLogError("Error removing video: \(error)")
                    }
                }
                message.error = copyError
                self.connection.readWrite({ (transaction) in
                    mediaItem.save(with: transaction)
                    message.save(with: transaction)
                })
                self.send(mediaItem: mediaItem, prefetchedData: prefetchedData, message: message)
            }, completionQueue: self.internalQueue)
        }
    }
    
    public func send(audioURL url: URL, buddy: OTRBuddy) {
        internalQueue.async {
            self.send(url: url, buddy: buddy, type: .audio)
        }
    }
    
    public func send(image: UIImage, buddy: OTRBuddy) {
        internalQueue.async {
            guard let service = self.servers.first, service.maxSize > 0 else {
                DDLogError("No HTTP upload service available!")
                return
            }
            let filename = "\(UUID().uuidString).jpg"
            let imageItem = OTRImageItem(filename: filename, size: image.size, mimeType: "image/jpeg", isIncoming: false)
            let message = self.newOutgoingMessage(to: buddy, mediaItem: imageItem)
            self.connection.readWrite({ (transaction) in
                message.save(with: transaction)
                imageItem.save(with: transaction)
            })
            guard let ourImageData = image.jpegData(dataSize: .unlimited, resize: UIImage.Quality.high, jpeg: UIImage.Quality.high, maxTries: 10) else {
                DDLogError("Could not make JPEG out of image!")
                return
            }
            OTRMediaFileManager.shared.setData(ourImageData, for: imageItem, buddyUniqueId: buddy.uniqueId, completion: { (bytesWritten: Int, error: Error?) in
                self.connection.readWrite({ (transaction) in
                    imageItem.touchParentMessage(with: transaction)
                    if let error = error {
                        message.error = error
                        message.save(with: transaction)
                    }
                })
                if UInt(ourImageData.count) <= service.maxSize {
                    self.send(mediaItem: imageItem, prefetchedData: ourImageData, message: message)
                    return
                } else if let imageData = image.jpegData(dataSize: .maxBytes(service.maxSize), resize: UIImage.Quality.medium, jpeg: UIImage.Quality.medium, maxTries: 10) {
                    self.send(mediaItem: imageItem, prefetchedData: imageData, message: message)
                } else {
                    DDLogError("Could not make JPEG out of image! Bad size")
                }
            }, completionQueue: self.internalQueue)
        }
    }
    
    private func newOutgoingMessage(to buddy: OTRBuddy, mediaItem: OTRMediaItem) -> OTROutgoingMessage {
        let message = OTROutgoingMessage()!
        var security: OTRMessageTransportSecurity = .invalid
        self.connection.read({ (transaction) in
            security = buddy.preferredTransportSecurity(with: transaction)
        })
        message.buddyUniqueId = buddy.uniqueId
        message.mediaItemUniqueId = mediaItem.uniqueId
        message.messageSecurityInfo = OTRMessageEncryptionInfo(messageSecurity: security)
        return message
    }
    
    public func send(mediaItem: OTRMediaItem, prefetchedData: Data?, message: OTROutgoingMessage) {
        var shouldEncrypt = false
        switch message.messageSecurity {
        case .OMEMO, .OTR:
            shouldEncrypt = true
        case .invalid, .plaintext, .plaintextWithOTR:
            shouldEncrypt = false
        }
        
        self.upload(mediaItem: mediaItem, shouldEncrypt: shouldEncrypt, prefetchedData: prefetchedData, completion: { (_url: URL?, error: Error?) in
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
                mediaItem.transferProgress = 1.0
                message.text = url.absoluteString
                mediaItem.save(with: transaction)
                message.save(with: transaction)
            })
            self.queueOutgoingMessage(message: message)
        })
    }
    
    private func queueOutgoingMessage(message: OTROutgoingMessage) {
        let sendAction = OTRYapMessageSendAction(forMessage: message, date: nil)
        self.connection.readWrite { transaction in
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

// MARK: - Scanning and downloading incoming media
extension FileTransferManager {
    
    /** creates downloadmessages and then downloads if needed. parent message should already be saved! @warn Do not call from within an existing db transaction! */
    public func createAndDownloadItemsIfNeeded(message: OTRMessageProtocol, readConnection: YapDatabaseConnection, force: Bool) {
        if message.messageMediaItemKey != nil || message.messageText?.characters.count == 0 || message.downloadableURLs.count == 0 {
            DDLogVerbose("Download of message not needed \(message.messageKey)")
            return
        }
        var downloads: [OTRDownloadMessage] = []
        var disableAutomaticURLFetching = false
        if !force {
            readConnection.read { (transaction) in
                downloads = message.existingDownloads(with: transaction)
                if let thread = message.threadOwner(with: transaction), let account = OTRAccount.fetchObject(withUniqueID: thread.threadAccountIdentifier(), transaction: transaction) {
                    disableAutomaticURLFetching = account.disableAutomaticURLFetching
                }
            }
        }
        if downloads.count == 0 {
            downloads = message.downloads()
            if downloads.count == 0 {
                return
            }
            connection.readWrite({ (transaction) in
                for download in downloads {
                    if disableAutomaticURLFetching {
                        let media = OTRMediaItem.incomingItem(withFilename: download.downloadableURL.absoluteString, mimeType: nil)
                        media.save(with: transaction)
                        download.mediaItemUniqueId = media.uniqueId
                        download.error = FileTransferError.automaticDownloadsDisabled
                    }
                    download.save(with: transaction)
                }
            })
        }
        if disableAutomaticURLFetching {
            DDLogVerbose("Automatic URL fetching disabled \(message.messageKey)")
            return
        }
        for download in downloads {
            downloadMediaIfNeeded(download)
        }
    }
    
    /** Downloads media for a single downloadmessage */
    public func downloadMediaIfNeeded(_ downloadMessage: OTRDownloadMessage) {
        // Bail out if we've already downloaded the media
        if downloadMessage.mediaItemUniqueId != nil &&
            downloadMessage.error == nil {
            // DDLogWarn("Already downloaded media for this item")
            return
        }
        let url = downloadMessage.downloadableURL
        self.sessionManager.session.getTasksWithCompletionHandler { (tasks, _, _) in
            // Bail out if we've already got a task for this
            for task in tasks where task.originalRequest?.url == url {
                DDLogWarn("Already have outstanding task: \(task)")
                return
            }
            self.sessionManager.request(url, method: .head)
                .validate()
                .responseData(queue: self.internalQueue) { response in
                switch response.result {
                case .success:
                    DDLogInfo("HEAD response: \(String(describing: response.response?.allHeaderFields))")
                    if let headers = response.response?.allHeaderFields {
                        let contentType = headers["Content-Type"] as? String
                        let contentLength = headers["Content-Length"] as? UInt ?? 0
                        self.continueDownloading(downloadMessage: downloadMessage, url: url, contentType: contentType, contentLength: contentLength)
                    }
                case .failure(let error):
                    self.setError(error, onMessage: downloadMessage)
                    DDLogError("HEAD error: \(error)")
                }
            }
        }
    }
    
    private func setError(_ error: Error, onMessage downloadMessage: OTRDownloadMessage) {
        self.connection.readWrite { transaction in
            if let message = downloadMessage.refetch(with: transaction) {
                message.error = error
                message.save(with: transaction)
            }
        }
    }
    
    private func continueDownloading(downloadMessage: OTRDownloadMessage, url: URL, contentType: String?, contentLength: UInt) {
        var mediaItem: OTRMediaItem? = nil
        self.connection.readWrite { transaction in
            // Remove placeholder media item
            mediaItem = OTRMediaItem(forMessage: downloadMessage, transaction: transaction)
            mediaItem?.remove(with: transaction)
            mediaItem = OTRMediaItem.incomingItem(withFilename: url.lastPathComponent, mimeType: contentType)
            mediaItem?.save(with: transaction)
            downloadMessage.mediaItemUniqueId = mediaItem?.uniqueId
            downloadMessage.save(with: transaction)
        }
        guard let media = mediaItem else {
            DDLogError("Could not unwrap media item")
            self.setError(FileTransferError.fileNotFound, onMessage: downloadMessage)
            return
        }
        DDLogVerbose("Downloading media item at URL: \(url)")
        self.sessionManager.request(url)
            .validate()
            .responseData(queue: self.internalQueue) { response in
                self.finishDownload(downloadMessage: downloadMessage, mediaItem: media, inData: response.data, urlResponse: response.response, error: response.error)
                switch response.result {
                case .success:
                    DDLogVerbose("Download Successful")
                case .failure(let error):
                    self.setError(error, onMessage: downloadMessage)
                    DDLogError("Download Error \(error)")
                }
            }.downloadProgress(queue: self.internalQueue) { progress in
                DDLogVerbose("Download progress \(progress.fractionCompleted)")
                self.connection.asyncReadWrite { transaction in
                    if let media = media.refetch(with: transaction) {
                        media.transferProgress = Float(progress.fractionCompleted)
                        media.save(with: transaction)
                        media.touchParentMessage(with: transaction)
                    }
                }
        }
    }
    
    private func finishDownload(downloadMessage: OTRDownloadMessage, mediaItem: OTRMediaItem, inData: Data?, urlResponse: URLResponse?, error: Error?) {
        if let error = error {
            self.setError(error, onMessage: downloadMessage)
            DDLogError("Error downloading file \(error)")
            return
        }
        guard var data = inData, let response = urlResponse, let url = response.url else {
            self.setError(FileTransferError.fileNotFound, onMessage: downloadMessage)
            DDLogError("No data or response")
            return
        }
        DDLogVerbose("Received response \(response)")
        let authTagSize = 16 // i'm not sure if this can be assumed, but how else would we know the size?
        if let (key, iv) = url.aesGcmKey, data.count > authTagSize {
            DDLogVerbose("Received encrypted response, attempting decryption...")
            
            let cryptedData = data.subdata(in: 0..<data.count - authTagSize)
            let authTag = data.subdata(in: data.count - authTagSize..<data.count)
            let cryptoData = OTRCryptoData(data: cryptedData, authTag: authTag)
            do {
                data = try OTRCryptoUtility.decryptAESGCMData(cryptoData, key: key, iv: iv)
            } catch let error {
                self.setError(error, onMessage: downloadMessage)
                DDLogError("Error decrypting data: \(error)")
                return
            }
            DDLogVerbose("Decrpytion successful")
        }
        OTRMediaFileManager.sharedInstance().setData(data, for: mediaItem, buddyUniqueId: downloadMessage.buddyUniqueId, completion: { (bytesWritten, error) in
            if let error = error {
                self.setError(error, onMessage: downloadMessage)
                DDLogError("Error copying data: \(error)")
                return
            }
            self.connection.asyncReadWrite({ (transaction) in
                mediaItem.transferProgress = 1.0
                mediaItem.save(with: transaction)
                if let message = downloadMessage.refetch(with: transaction) {
                    message.error = nil
                    message.save(with: transaction)
                }
            }, completionQueue: DispatchQueue.main,
               completionBlock: {
                UIApplication.shared.showLocalNotification(downloadMessage)
            })
        }, completionQueue: nil)
    }
}

extension OTRDownloadMessage {
    /// Turn aesgcm links into https links
    var downloadableURL: URL {
        var downloadableURL = url
        if url.isAesGcm, var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            components.scheme = URLScheme.https.rawValue
            if let rawURL = components.url {
                downloadableURL = rawURL
            }
        }
        return downloadableURL
    }
}

public extension OTRMessageProtocol {
    public var downloadableURLs: [URL] {
        return self.messageText?.downloadableURLs ?? []
    }
}

public extension OTRBaseMessage {
    @objc public var downloadableNSURLs: [NSURL] {
        return self.downloadableURLs as [NSURL]
    }
}

public extension OTRXMPPRoomMessage {
    @objc public var downloadableNSURLs: [NSURL] {
        return self.downloadableURLs as [NSURL]
    }
}

// MARK: - Extensions

fileprivate extension XMPPMessage {
    /** XEP-0066: Out of Band Data jabber:x:oob */
    var outOfBandURL: URL? {
        guard let oob = elements(forXmlns: "jabber:x:oob").first as? XMLElement,
            let urlElement = oob.elements(forName: "url").first,
            let urlString = urlElement.stringValue else {
                return nil
        }
        let url = URL(string: urlString)
        return url
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

enum URLScheme: String {
    case https = "https"
    case aesgcm = "aesgcm"
    static let downloadableSchemes: [URLScheme] = [.https, .aesgcm]
}

extension URL {
    
    /** URL scheme matches aesgcm:// */
    var isAesGcm: Bool {
        return scheme == URLScheme.aesgcm.rawValue
    }
    
    /** Has hex anchor with key and IV. 48 bytes w/ 16 iv + 32 key */
    var anchorData: Data? {
        guard let anchor = self.fragment else { return nil }
        let data = anchor.dataFromHex()
        return data
    }
    
    var aesGcmKey: (key: Data, iv: Data)? {
        guard let data = self.anchorData, data.count == 48 else { return nil }
        let iv = data.subdata(in: 0..<16)
        let key = data.subdata(in: 16..<48)
        return (key, iv)
    }
}

public extension NSString {
    public var isSingleURLOnly: Bool {
        return (self as String).isSingleURLOnly
    }
}

public extension String {
    
    private var urlRanges: ([URL], [NSRange]) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return ([], [])
        }
        var urls: [URL] = []
        var ranges: [NSRange] = []
        let matches = detector.matches(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count))
        for match in matches where match.resultType == .link {
            if let url = match.url {
                urls.append(url)
                ranges.append(match.range)
            }
        }
        return (urls, ranges)
    }
    
    /** Grab any URLs from a string */
    public var urls: [URL] {
        let (urls, _) = urlRanges
        return urls
    }
    
    /** Returns true if the message is ONLY a single URL */
    public var isSingleURLOnly: Bool {
        let (_, ranges) = urlRanges
        guard ranges.count == 1,
            let range = ranges.first,
            range.length == self.characters.count else {
            return false
        }
        return true
    }
    
    /** Use this for extracting potentially downloadable URLs from a message. Currently checks for https:// and aesgcm:// */
    public var downloadableURLs: [URL] {
        return urlsMatchingSchemes(URLScheme.downloadableSchemes)
    }
    
    fileprivate func urlsMatchingSchemes(_ schemes: [URLScheme]) -> [URL] {
        let urls = self.urls.filter {
            guard let scheme = $0.scheme else { return false }
            for inScheme in schemes where inScheme.rawValue == scheme {
                return true
            }
            return false
        }
        return urls
    }
}
