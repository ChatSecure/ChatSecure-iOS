//
//  OTRServerCapabilities.m
//  ChatSecure
//
//  Created by Chris Ballinger on 2/9/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "OTRServerCapabilities.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_INFO | XMPP_LOG_FLAG_SEND_RECV; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

static NSString *const XMPPDiscoverItemsNamespace = @"http://jabber.org/protocol/disco#items";
static NSString *const OTRServerCapabilitiesErrorDomain = @"OTRServerCapabilitiesErrorDomain";

@interface OTRServerCapabilities()
@property (nonatomic, strong, readonly) XMPPIDTracker *tracker;
/** Only access this from within the moduleQueue */
@property (nonatomic, readwrite) BOOL hasRequestedServices;
/** This contains all JIDs that need to be fetched. */
@property (nonatomic, strong, readonly) NSMutableSet <XMPPJID*> *allJIDs;
@end

@implementation OTRServerCapabilities
@synthesize autoDiscoverServices = _autoDiscoverServices;
@synthesize discoveredServices = _discoveredServices;
@synthesize allCapabilities = _allCapabilities;

- (instancetype) initWithCapabilities:(XMPPCapabilities *)capabilities dispatchQueue:(dispatch_queue_t)dispatchQueue {
    if (self = [super initWithDispatchQueue:dispatchQueue]) {
        _capabilities = capabilities;
        _autoDiscoverServices = YES;
        _allJIDs = [NSMutableSet set];
        _hasRequestedServices = NO;
        _autoFetchAllCapabilities = YES;
    }
    return self;
}

#pragma mark Setup

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    if ([super activate:aXmppStream])
    {
        [self performBlock:^{
            [self.capabilities addDelegate:self delegateQueue:self->moduleQueue];
            self->_tracker = [[XMPPIDTracker alloc] initWithStream:aXmppStream dispatchQueue:self->moduleQueue];
        }];
        return YES;
    }
    
    return NO;
}

- (void) deactivate {
    [self performBlock:^{
        [self->_tracker removeAllIDs];
        self->_tracker = nil;
        [self.capabilities removeDelegate:self];
        self.discoveredServices = nil;
    }];
    [super deactivate];
}


#pragma mark Public Properties

- (BOOL) autoDiscoverServices {
    __block BOOL discover = NO;
    [self performBlock:^{
        discover = self->_autoDiscoverServices;
    }];
    return discover;
}

- (void) setAutoDiscoverServices:(BOOL)autoDiscoverServices {
    [self performBlockAsync:^{
        [self willChangeValueForKey:NSStringFromSelector(@selector(autoDiscoverServices))];
        self->_autoDiscoverServices = autoDiscoverServices;
        [self didChangeValueForKey:NSStringFromSelector(@selector(autoDiscoverServices))];
    }];
}

- (void) setDiscoveredServices:(NSArray<NSXMLElement *> * _Nullable)discoveredServices {
    [self performBlockAsync:^{
        [self willChangeValueForKey:NSStringFromSelector(@selector(discoveredServices))];
        self->_discoveredServices = [discoveredServices copy];
        [self didChangeValueForKey:NSStringFromSelector(@selector(discoveredServices))];
    }];
}

- (nullable NSArray<NSXMLElement *>*) discoveredServices {
    __block NSArray<NSXMLElement *> *services = nil;
    [self performBlock:^{
        services = self->_discoveredServices;
    }];
    return services;
}

- (void) setAllCapabilities:(NSDictionary<XMPPJID *,NSXMLElement *> * _Nullable)allCapabilities {
    [self performBlockAsync:^{
        [self willChangeValueForKey:NSStringFromSelector(@selector(allCapabilities))];
        self->_allCapabilities = [allCapabilities copy];
        [self didChangeValueForKey:NSStringFromSelector(@selector(allCapabilities))];
    }];
}

- (nullable NSDictionary<XMPPJID*, NSXMLElement *> *) allCapabilities {
    __block NSDictionary<XMPPJID*, NSXMLElement *> *caps = nil;
    [self performBlock:^{
        caps = self->_allCapabilities;
    }];
    return caps;
}

- (NSXMLElement*) streamFeatures {
    __block NSXMLElement *features = nil;
    [self performBlock:^{
        if (self->xmppStream.state >= STATE_XMPP_POST_NEGOTIATION) {
            features = [[self->xmppStream.rootElement elementForName:@"stream:features"] copy];
        }
    }];
    return features;
}

#pragma mark Public Methods

/**
 * This method provides functionality of XEP-0045 6.1 Discovering a MUC Service.
 *
 * @link {http://xmpp.org/extensions/xep-0045.html#disco-service}
 *
 * Example 1. Entity Queries Server for Associated Services
 *
 * <iq from='hag66@shakespeare.lit/pda'
 *       id='h7ns81g'
 *       to='shakespeare.lit'
 *     type='get'>
 *   <query xmlns='http://jabber.org/protocol/disco#items'/>
 * </iq>
 */
- (void)discoverServices
{
    // This is a public method, so it may be invoked on any thread/queue.
    [self performBlockAsync:^{
        if (self->_hasRequestedServices) return; // We've already requested services
        if (self->_discoveredServices) { // We've already discovered the services
            [self->multicastDelegate serverCapabilities:self didDiscoverServices:self->_discoveredServices];
            return;
        }
        
        NSString *toStr = self->xmppStream.myJID.domain;
        NSXMLElement *query = [NSXMLElement elementWithName:@"query"
                                                      xmlns:XMPPDiscoverItemsNamespace];
        XMPPIQ *iq = [XMPPIQ iqWithType:@"get"
                                     to:[XMPPJID jidWithString:toStr]
                              elementID:[self->xmppStream generateUUID]
                                  child:query];
        if (!iq) {
            XMPPLogInfo(@"OTRServerCapabilities: Could not discover services for stream: %@", self->xmppStream);
            return;
        }
        XMPPLogInfo(@"OTRServerCapabilities: Discovering services for domain %@...", toStr);

        [self.tracker addElement:iq
                           target:self
                         selector:@selector(handleDiscoverServicesQueryIQ:withInfo:)
                          timeout:15];
        
        [self->xmppStream sendElement:iq];
        self->_hasRequestedServices = YES;
    }];
}

/**
 * This method will fetch all capabilities for your server, your JID, and all services.
 * It will automatically call discoverServices if needed.
 */
- (void)fetchAllCapabilities {
    [self performBlockAsync:^{
        if (self->xmppStream.state != STATE_XMPP_CONNECTED) {
            XMPPLogError(@"OTRServerCapabilities: fetchAllCapabilities error - not connected. %@", self);
            return;
        }
        if (![self->xmppStream isAuthenticated]) {
            XMPPLogError(@"OTRServerCapabilities: fetchAllCapabilities error - not authenticated. %@", self);
            return;
        }
        [self discoverServices];
        [self fetchCapabilitiesForJIDs:self.allJIDs];
    }];
}

#pragma mark XMPPStream delegate

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self performBlockAsync:^{
        XMPPJID *myJID = sender.myJID;
        if (myJID) {
            // keep track of JIDs we care about
            [self.allJIDs addObject:myJID.bareJID]; // the spec says to use full, but I disagree
            // [self.allJIDs addObject:myJID];
            [self.allJIDs addObject:myJID.domainJID];
        }
        if (!self->_autoDiscoverServices) {
            return;
        }
        [self discoverServices];
        if (!self->_autoFetchAllCapabilities) {
            return;
        }
        [self fetchCapabilitiesForJIDs:self.allJIDs];
    }];
}

- (BOOL)xmppStream:(XMPPStream *)stream didReceiveIQ:(XMPPIQ *)iq
{
    NSString *type = [iq type];
    __block BOOL result = NO;
    if ([type isEqualToString:@"result"] || [type isEqualToString:@"error"]) {
        [self performBlock:^{
            result = [self.tracker invokeForElement:iq withObject:iq];
        }];
    }
    return result;
}

#pragma mark XMPPIDTracker

/**
 * This method handles the response received (or not received) after calling discoverServices.
 * This is borrowed from XMPPMUC.m
 */
- (void)handleDiscoverServicesQueryIQ:(XMPPIQ *)iq withInfo:(XMPPBasicTrackingInfo *)info
{
    [self performBlockAsync:^{
        self->_hasRequestedServices = NO; // Set this back to NO to allow for future requests
        NSError *error = nil;
        if (!iq) {
            NSDictionary *dict = @{NSLocalizedDescriptionKey : @"The request timed out.",
                                   @"trackingInfo": info};
            error = [NSError errorWithDomain:OTRServerCapabilitiesErrorDomain
                                                 code:1000
                                             userInfo:dict];
        } else {
            NSXMLElement *errorElem = [iq elementForName:@"error"];
            
            if (errorElem) {
                NSString *errMsg = [errorElem.children componentsJoinedByString:@", "];
                NSDictionary *dict = @{NSLocalizedDescriptionKey : errMsg};
                error = [NSError errorWithDomain:OTRServerCapabilitiesErrorDomain
                                                     code:[errorElem attributeIntegerValueForName:@"code"
                                                                                 withDefaultValue:0]
                                                 userInfo:dict];
            }
        }
        if (error) {
            XMPPLogError(@"OTRServerCapabilities: Error discovering services for domain %@: %@", self->xmppStream.myJID.domain, error);
            [self->multicastDelegate serverCapabilitiesFailedToDiscoverServices:self
                                                                withError:error];
            
            // Deal with the race condition where we've already fetched your JID and server caps
            // but for whatever reason fetching services fails.
            NSSet *allCaps = [NSSet setWithArray:self.allCapabilities.allKeys];
            if ([self.allJIDs isEqualToSet:allCaps]) {
                [self->multicastDelegate serverCapabilities:self didDiscoverCapabilities:self.allCapabilities];
            }
            return;
        }
        
        NSXMLElement *query = [iq elementForName:@"query"
                                           xmlns:XMPPDiscoverItemsNamespace];
        
        NSArray<NSXMLElement*> *items = [query elementsForName:@"item"];
        if (!items) {
            items = @[];
        }
        self.discoveredServices = [items copy];
        [self->multicastDelegate serverCapabilities:self didDiscoverServices:items];
        
        XMPPLogInfo(@"OTRServerCapabilities: Discovered services for domain %@:\n%@", self->xmppStream.myJID.domain, items);

        // Recursively fetch service capabilities if needed
        if (!self->_autoFetchAllCapabilities) {
            return;
        }
        NSSet<XMPPJID*> *jids = [self jidsFromItems:self->_discoveredServices];
        [self.allJIDs unionSet:jids];
        [self fetchCapabilitiesForJIDs:jids];
    }];
}

#pragma mark XMPPCapabilitiesDelegate

/**
 * Invoked when capabilities fetch has timed out.
 *
 * This code depends on pending upstream XMPPFramework changes
 **/
- (void)xmppCapabilities:(XMPPCapabilities *)sender fetchFailedForJID:(XMPPJID *)jid {
    XMPPLogInfo(@"OTRServerCapabilities: Fetch failed for jid %@", [jid full]);
    [self performBlockAsync:^{
        NSSet<XMPPJID*>* jids = self.allJIDs;
        if (!jids.count) {
            return;
        }
        // Check if this is something we care about
        if (![jids containsObject:jid]) {
            return;
        }
        // Skip caps we've already fetched
        NSXMLElement *existingCaps = [self.allCapabilities objectForKey:jid];
        if (existingCaps) {
            return;
        }
        // This seems to be needed because fetching your own capabilities has been failing on the first try, but works on second try.
        // TODO: limit number of retries
        [self.capabilities fetchCapabilitiesForJID:jid];
    }];
}

- (void)xmppCapabilities:(XMPPCapabilities *)sender didDiscoverCapabilities:(NSXMLElement *)caps forJID:(XMPPJID *)jid {
    [self performBlockAsync:^{
        NSSet<XMPPJID*>* jids = self.allJIDs;
        if (!jids.count) {
            return;
        }
        // Check if this is something we care about
        if (![jids containsObject:jid]) {
            return;
        }
        XMPPLogInfo(@"OTRServerCapabilities: Discovered capabilities for jid %@:\n%@", [jid full], caps.prettyXMLString);
        NSMutableDictionary<XMPPJID*, NSXMLElement *> *newCaps = [self.allCapabilities mutableCopy];
        if (!newCaps) {
            newCaps = [NSMutableDictionary dictionaryWithCapacity:jids.count];
        }
        [newCaps setObject:caps forKey:jid];
        self.allCapabilities = newCaps;
        [self->multicastDelegate serverCapabilities:self didDiscoverCapabilities:self.allCapabilities];
    }];
}

#pragma mark Utility

/**
 * This lets you extract all features from the allCapabilities property.
 */
+ (NSSet<NSString*>*) allFeaturesForCapabilities:(NSDictionary<XMPPJID*, NSXMLElement *>*)capabilities streamFeatures:(NSXMLElement*)streamFeatures {
    NSMutableSet *allFeatures = [NSMutableSet set];
    [capabilities enumerateKeysAndObjectsUsingBlock:^(XMPPJID * _Nonnull key, NSXMLElement * _Nonnull query, BOOL * _Nonnull stop) {
        NSArray<NSXMLElement*> *features = [query elementsForName:@"feature"];
        [features enumerateObjectsUsingBlock:^(NSXMLElement * _Nonnull feature, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *value = [feature attributeStringValueForName:@"var"];
            if (value) {
                [allFeatures addObject:value];
            }
        }];
    }];
    [streamFeatures.children enumerateObjectsUsingBlock:^(NSXMLNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([node isKindOfClass:[NSXMLElement class]]) {
            NSXMLElement *element = (NSXMLElement*)node;
            NSString *namespace = [element xmlns];
            if (namespace) {
                [allFeatures addObject:namespace];
            }
        }
    }];
    return [allFeatures copy];
}

- (void) fetchCapabilitiesForJIDs:(NSSet<XMPPJID*>*)jids {
    NSAssert(dispatch_get_specific(moduleQueueTag), @"Invoked on incorrect queue");
    NSMutableDictionary<XMPPJID*, NSXMLElement *> *newCaps = [_allCapabilities mutableCopy];
    if (!newCaps) {
        newCaps = [NSMutableDictionary dictionaryWithCapacity:jids.count];
    }
    [jids enumerateObjectsUsingBlock:^(XMPPJID * _Nonnull jid, BOOL * _Nonnull stop) {
        // Skip caps we've already fetched
        NSXMLElement *existingCaps = [newCaps objectForKey:jid];
        if (existingCaps) {
            return;
        }
        id <XMPPCapabilitiesStorage> storage = self.capabilities.xmppCapabilitiesStorage;
        BOOL fetched = [storage areCapabilitiesKnownForJID:jid xmppStream:self->xmppStream];
        if (fetched) {
            NSXMLElement *capabilities = [storage capabilitiesForJID:jid xmppStream:self->xmppStream];
            if (capabilities) {
                [newCaps setObject:capabilities forKey:jid];
                *stop = YES;
            }
        } else {
            [self.capabilities fetchCapabilitiesForJID:jid];
        }
    }];
    self.allCapabilities = newCaps;
    [multicastDelegate serverCapabilities:self didDiscoverCapabilities:self.allCapabilities];
}

- (NSSet<XMPPJID*>*) jidsFromItems:(NSArray<NSXMLElement*>*)items {
    if (!items.count) { return [NSSet set]; }
    NSMutableSet *jids = [NSMutableSet setWithCapacity:items.count];
    [items enumerateObjectsUsingBlock:^(NSXMLElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *jidStr = [obj attributeStringValueForName:@"jid"];
        if (!jidStr) { return; }
        XMPPJID *jid = [XMPPJID jidWithString:jidStr];
        if (!jid) { return; }
        [jids addObject:jid];
    }];
    return jids;
}

@end
