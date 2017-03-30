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
    /// This won't be set until OTRServerCapabilities has iterated the services and capabilities
    var httpFileUpload: XMPPHTTPFileUpload?
    var serverCapabilities: OTRServerCapabilities
    
    deinit {
        serverCapabilities.removeDelegate(self)
    }
    
    public init(serverCapabilities: OTRServerCapabilities) {
        self.serverCapabilities = serverCapabilities
        super.init()
        serverCapabilities.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.refreshCapabilities()
    }
    
    // MARK: - Public Methods
    
    /// This will fetch capabilities and setup XMPP transfer module if needed
    public func refreshCapabilities() {
        if httpFileUpload != nil {
            return
        }
        guard let allCapabilities = serverCapabilities.allCapabilities else {
            return
        }
        createHTTPUploadModuleIfNeeded(capabilities: allCapabilities)
        if httpFileUpload != nil {
            // this has no effect if youre not connected
            serverCapabilities.fetchAllCapabilities()
        }
    }
    
    // MARK: - Private Methods
    
    /// This will create the httpFileUpload object if needed
    private func createHTTPUploadModuleIfNeeded(capabilities: [XMPPJID : XMLElement]) {
        if httpFileUpload != nil {
            return
        }
        let servers = self.serversFromCapabilities(capabilities: capabilities)
        // Only bother with the first http server result for now
        guard let server = servers.first else { return }
        self.httpFileUpload = XMPPHTTPFileUpload(serviceName: server.jid.bare(), dispatchQueue: DispatchQueue.main)
    }
    
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
    
    public func xmppHTTPFileUpload(_ sender: XMPPHTTPFileUpload!, didAssign slot: XMPPSlot!) {
        
    }
    
    public func xmppHTTPFileUpload(_ sender: XMPPHTTPFileUpload!, didFailToAssignSlotWithError iqError: XMPPIQ!) {
        
    }
    
    // MARK: - OTRServerCapabilitiesDelegate
    
    public func serverCapabilities(_ sender: OTRServerCapabilities, didDiscoverCapabilities capabilities: [XMPPJID : XMLElement]) {
        createHTTPUploadModuleIfNeeded(capabilities: capabilities)
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
