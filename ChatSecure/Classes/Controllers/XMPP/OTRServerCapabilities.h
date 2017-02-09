//
//  OTRServerCapabilities.h
//  ChatSecure
//
//  Created by Chris Ballinger on 2/9/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import <XMPPFramework/XMPPFramework.h>

@protocol OTRServerCapabilitiesDelegate;

NS_ASSUME_NONNULL_BEGIN
/**
 * This module will recursively check all of the server's capabilities by first
 * doing a disco#items check, and then doing a disco#info check on each item.
 * The disco#items code is borrowed from XMPPMUC.
 *
 * It depends on the XMPPCapabilities module, so make sure you have that enabled.
 */
@interface OTRServerCapabilities : XMPPModule

/** Default is YES. discoverServices will be invoked after xmppStreamDidAuthenticate: */
@property (atomic, readwrite) BOOL autoDiscoverServices;

/** Default is YES. Automatically fetch capabilities for your server, full JID, and services */
@property (atomic, readwrite) BOOL autoFetchAllCapabilities;

/** This property will be non-nil after serverCapabilities:didDiscoverServices: is complete. */
@property (atomic, copy, readonly, nullable) NSArray<NSXMLElement *> *discoveredServices;

/** 
 * This property contains everything we've discovered about capabilities.
 * Includes your server, your JID, and all services.
 * Will be non-nil after serverCapabilities:didDiscoverAllCapabilities:
 * is complete.
 */
@property (atomic, copy, readonly, nullable) NSDictionary<XMPPJID*, NSXMLElement *> *allCapabilities;

/**
 * This method will fetch all capabilities for your server, your JID, and all services.
 * It will automatically call discoverServices if needed.
 */
- (void)fetchAllCapabilities;

/**
 * This method will attempt to discover existing services for the domain found in xmppStream.myJID. It caches the result and will return immediately if cached.
 *
 * @see serverCapabilities:didDiscoverServices:
 * @see serverCapabilitiesFailedToDiscoverServices:withError:
 */
- (void)discoverServices;

@end

@protocol OTRServerCapabilitiesDelegate <NSObject>

/**
 * This will be called when all of the capabilities of your server, your JID,
 * and all services are fetched.
 * After this is called the allCapabilities property will be non-nil.
 */
- (void)serverCapabilities:(OTRServerCapabilities *)sender didDiscoverAllCapabilities:(NSDictionary<XMPPJID*, NSXMLElement *>*) allCapabilities;

/**
 * Implement this method when calling [mucInstance discoverServices]. It will be invoked if the request
 * for discovering services is successfully executed and receives a successful response.
 *
 * @param sender OTRServerCapabilities object invoking this delegate method.
 * @param services An array of NSXMLElements in the form shown below. You will need to extract the data you
 *                 wish to use.
 *
 *                 <item jid='chat.shakespeare.lit' name='Chatroom Service'/>
 */
- (void)serverCapabilities:(OTRServerCapabilities *)sender didDiscoverServices:(NSArray<NSXMLElement *> *)services;

/**
 * Implement this method when calling [mucInstanse discoverServices]. It will be invoked if the request
 * for discovering services is unsuccessfully executed or receives an unsuccessful response.
 *
 * @param sender OTRServerCapabilities object invoking this delegate method.
 * @param error NSError containing more details of the failure.
 */
- (void)serverCapabilitiesFailedToDiscoverServices:(OTRServerCapabilities *)sender withError:(NSError *)error;


@end
NS_ASSUME_NONNULL_END
