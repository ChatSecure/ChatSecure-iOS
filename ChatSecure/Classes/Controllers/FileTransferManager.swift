//
//  FileTransferManager.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 3/28/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation
import XMPPFramework

public class FileTransferManager: NSObject, XMPPHTPPFileUploadDelegate, OTRServerCapabilitiesDelegate {

    var httpFileUpload: XMPPHTTPFileUpload
    var serverCapabilities: OTRServerCapabilities
    private var servers: [HTTPServer] = []
    
    deinit {
        httpFileUpload.removeDelegate(self)
        serverCapabilities.removeDelegate(self)
    }
    
    public init(serverCapabilities: OTRServerCapabilities) {
        self.serverCapabilities = serverCapabilities
        self.httpFileUpload = XMPPHTTPFileUpload()
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
    
    // MARK: - XMPPHTPPFileUploadDelegate
    
    public func xmppHTTPFileUpload(_ sender: XMPPHTTPFileUpload, service: XMPPJID, didAssign slot: XMPPSlot) {
        
    }
    
    public func xmppHTTPFileUpload(_ sender: XMPPHTTPFileUpload, service: XMPPJID, didFailToAssignSlotWithError iqError: XMPPIQ) {
        
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
