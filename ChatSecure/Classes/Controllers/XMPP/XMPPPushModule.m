//
//  XMPPPushModule.m
//  ChatSecure
//
//  Created by Chris Ballinger on 2/27/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

#import "XMPPPushModule.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int xmppLogLevel = XMPP_LOG_LEVEL_INFO | XMPP_LOG_FLAG_SEND_RECV; // | XMPP_LOG_FLAG_TRACE;
#else
static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

@interface XMPPPushModule()
@property (nonatomic, strong, readonly) XMPPIDTracker *tracker;
/** Only access this from within the moduleQueue */
@property (nonatomic, strong, readonly) NSMutableSet <XMPPCapabilities*> *capabilitiesModules;
/** Prevents multiple requests. Only access this from within the moduleQueue */
@property (nonatomic) BOOL isRegistering;
@end

@implementation XMPPPushModule

#pragma mark Public API

/** Manually refresh your push registration */
- (void) registerForPushWithOptions:(XMPPPushOptions*)options
                          elementId:(nullable NSString*)elementId {
    __weak typeof(self) weakSelf = self;
    __weak id weakMulticast = multicastDelegate;
    [self performBlockAsync:^{
        if (self.isRegistering) {
            XMPPLogVerbose(@"Already registering push options...");
            return;
        }
        NSString *eid = [self fixElementId:elementId];
        XMPPIQ *enableElement = [XMPPIQ enableNotificationsElementWithJID:options.serverJID node:options.node options:options.formOptions elementId:eid];
        [self.tracker addElement:enableElement block:^(XMPPIQ *responseIq, id<XMPPTrackingInfo> info) {
            __typeof__(self) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            strongSelf.isRegistering = NO;
            if (!responseIq || [responseIq isErrorIQ]) {
                // timeout
                XMPPLogWarn(@"refreshRegistration error: %@ %@", enableElement, responseIq);
                [weakMulticast pushModule:strongSelf failedToRegisterWithErrorIq:responseIq outgoingIq:enableElement];
                return;
            }
            [weakMulticast pushModule:strongSelf didRegisterWithResponseIq:responseIq outgoingIq:enableElement];
        } timeout:30];
        self.isRegistering = YES;
        [xmppStream sendElement:enableElement];
    }];
}

/** Disables push for a specified node on serverJID. Warning: If node is nil it will disable for all nodes (and disable push on your other devices) */
- (void) disablePushForServerJID:(XMPPJID*)serverJID
                            node:(nullable NSString*)node
                       elementId:(nullable NSString*)elementId {
    __weak typeof(self) weakSelf = self;
    __weak id weakMulticast = multicastDelegate;
    [self performBlockAsync:^{
        NSString *eid = [self fixElementId:elementId];
        
        XMPPIQ *disableElement = [XMPPIQ disableNotificationsElementWithJID:serverJID node:node elementId:eid];
        [self.tracker addElement:disableElement block:^(XMPPIQ *responseIq, id<XMPPTrackingInfo> info) {
            __typeof__(self) strongSelf = weakSelf;
            if (!strongSelf) { return; }
            if (!responseIq || [responseIq isErrorIQ]) {
                // timeout
                XMPPLogWarn(@"disablePush error: %@ %@", disableElement, responseIq);
                [weakMulticast pushModule:strongSelf failedToDisablePushWithErrorIq:responseIq serverJID:serverJID node:node outgoingIq:disableElement];
                return;
            }
            [weakMulticast pushModule:strongSelf disabledPushForServerJID:serverJID node:node responseIq:responseIq outgoingIq:disableElement];
        } timeout:30];
        [xmppStream sendElement:disableElement];
    }];
}

#pragma mark Setup

- (BOOL)activate:(XMPPStream *)aXmppStream
{
    if ([super activate:aXmppStream])
    {
        [self performBlock:^{
            _capabilitiesModules = [NSMutableSet set];
            [xmppStream autoAddDelegate:self delegateQueue:moduleQueue toModulesOfClass:[XMPPCapabilities class]];
            _tracker = [[XMPPIDTracker alloc] initWithStream:aXmppStream dispatchQueue:moduleQueue];
            
            [xmppStream enumerateModulesWithBlock:^(XMPPModule *module, NSUInteger idx, BOOL *stop) {
                if ([module isKindOfClass:[XMPPCapabilities class]]) {
                    [self.capabilitiesModules addObject:(XMPPCapabilities*)module];
                }
            }];
        }];
        return YES;
    }
    
    return NO;
}

- (void) deactivate {
    [self performBlock:^{
        [_tracker removeAllIDs];
        _tracker = nil;
        [xmppStream removeAutoDelegate:self delegateQueue:moduleQueue fromModulesOfClass:[XMPPCapabilities class]];
        _capabilitiesModules = nil;
        _isRegistering = NO;
    }];
    [super deactivate];
}

#pragma mark XMPPStream Delegate

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    [self performBlockAsync:^{
        XMPPJID *jid = sender.myJID.bareJID;
        __block BOOL supportsPush = NO;
        [self.capabilitiesModules enumerateObjectsUsingBlock:^(XMPPCapabilities * _Nonnull capsModule, BOOL * _Nonnull stop) {
            id <XMPPCapabilitiesStorage> storage = capsModule.xmppCapabilitiesStorage;
            BOOL fetched = [storage areCapabilitiesKnownForJID:jid xmppStream:xmppStream];
            if (fetched) {
                NSXMLElement *capabilities = [storage capabilitiesForJID:jid xmppStream:xmppStream];
                if (capabilities) {
                    supportsPush = [self supportsPushFromCaps:capabilities];
                    *stop = YES;
                }
            } else {
                [capsModule fetchCapabilitiesForJID:jid];
            }
        }];
        if (supportsPush) {
            [multicastDelegate pushModuleReady:self];
        }
    }];
}


- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq {
    BOOL success = NO;
    if (!iq.from) {
        // Some error responses for self or contacts don't have a "from"
        success = [self.tracker invokeForID:iq.elementID withObject:iq];
    } else {
        success = [self.tracker invokeForElement:iq withObject:iq];
    }
    //DDLogWarn(@"Could not match IQ: %@", iq);
    return success;
}

- (void)xmppStream:(XMPPStream *)sender didRegisterModule:(id)module
{
    if (![module isKindOfClass:[XMPPCapabilities class]]) {
        return;
    }
    [self performBlockAsync:^{
        [self.capabilitiesModules addObject:(XMPPCapabilities*)module];
    }];
    
}

- (void)xmppStream:(XMPPStream *)sender willUnregisterModule:(id)module
{
    if (![module isKindOfClass:[XMPPCapabilities class]]) {
        return;
    }
    [self performBlockAsync:^{
        [self.capabilitiesModules removeObject:(XMPPCapabilities*)module];
    }];
}

#pragma mark XMPPCapabilitiesDelegate

- (void)xmppCapabilities:(XMPPCapabilities *)sender didDiscoverCapabilities:(NSXMLElement *)caps forJID:(XMPPJID *)jid {
    XMPPLogVerbose(@"%@: %@\n%@:%@", THIS_FILE, THIS_METHOD, jid, caps);
    NSString *myDomain = [self.xmppStream.myJID domain];
    if ([[jid bare] isEqualToString:[jid domain]]) {
        if (![[jid domain] isEqualToString:myDomain]) {
            // You're checking the server's capabilities but it's not your server(?)
            return;
        }
    } else {
        if (![[self.xmppStream.myJID bare] isEqualToString:[jid bare]]) {
            // You're checking someone else's capabilities
            return;
        }
    }
    BOOL supportsXEP = [self supportsPushFromCaps:caps];
    if (supportsXEP) {
        [multicastDelegate pushModuleReady:self];
    }
}

#pragma mark Utility

/** Generate elementId UUID if needed */
- (nonnull NSString*) fixElementId:(nullable NSString*)elementId {
    NSString *eid = nil;
    if (!elementId.length) {
        eid = [[NSUUID UUID] UUIDString];
    } else {
        eid = [elementId copy];
    }
    return eid;
}

/** Executes block synchronously on moduleQueue */
- (void) performBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_sync(moduleQueue, block);
}

/** Executes block asynchronously on moduleQueue */
- (void) performBlockAsync:(dispatch_block_t)block {
    if (dispatch_get_specific(moduleQueueTag))
        block();
    else
        dispatch_async(moduleQueue, block);
}

- (BOOL) supportsPushFromCaps:(NSXMLElement*)caps {
    __block BOOL supportsPushXEP = NO;
    NSArray <NSXMLElement*> *featureElements = [caps elementsForName:@"feature"];
    [featureElements enumerateObjectsUsingBlock:^(NSXMLElement * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *featureName = [obj attributeStringValueForName:@"var"];
        if ([featureName isEqualToString:XMPPPushXMLNS]){
            supportsPushXEP = YES;
            *stop = YES;
        }
    }];
    return supportsPushXEP;
}

@end

@implementation XMPPPushOptions

- (instancetype) initWithServerJID:(XMPPJID*)serverJID
                              node:(NSString*)node
                       formOptions:(NSDictionary<NSString*,NSString*>*)formOptions {
    NSParameterAssert(serverJID != nil);
    NSParameterAssert(node != nil);
    NSParameterAssert(formOptions != nil);
    if (self = [super init]) {
        _serverJID = [serverJID copy];
        _node = [node copy];
        _formOptions = [formOptions copy];
    }
    return self;
}

@end
