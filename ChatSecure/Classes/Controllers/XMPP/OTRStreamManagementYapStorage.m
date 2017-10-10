//
//  OTRStreamManagementYapStorage.m
//  ChatSecure
//
//  Created by David Chiles on 11/19/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRStreamManagementYapStorage.h"
@import XMPPFramework;
@import YapDatabase;
#import "OTRStreamManagementStorageObject.h"

@interface OTRStreamManagementYapStorage ()

@property (nonatomic, readonly) dispatch_queue_t parentQueue;

@end

@implementation OTRStreamManagementYapStorage

- (instancetype)initWithDatabaseConnection:(YapDatabaseConnection *)databaseConnection
{
    if (self = [super init]) {
        _databaseConnection = databaseConnection;
    }
    return self;
}

- (NSString *)accountUniqueIdForStream:(XMPPStream *)stream
{
    return stream.tag;
}

 #pragma - mark XMPPStramManagementDelegate Methods
//
//
// -- PRIVATE METHODS --
//
// These methods are designed to be used ONLY by the XMPPStreamManagement class.
//
//

/**
 * Configures the storage class, passing it's parent and the parent's dispatch queue.
 *
 * This method is called by the init methods of the XMPPStreamManagement class.
 * This method is designed to inform the storage class of it's parent
 * and of the dispatch queue the parent will be operating on.
 *
 * A storage class may choose to operate on the same queue as it's parent,
 * as the majority of the time it will be getting called by the parent.
 * If both are operating on the same queue, the combination may run faster.
 *
 * Some storage classes support multiple xmppStreams,
 * and may choose to operate on their own internal queue.
 *
 * This method should return YES if it was configured properly.
 * It should return NO only if configuration failed.
 * For example, a storage class designed to be used only with a single xmppStream is being added to a second stream.
 **/
- (BOOL)configureWithParent:(XMPPStreamManagement *)parent queue:(dispatch_queue_t)queue
{
    _parentQueue = queue;
    return YES;
}

- (OTRStreamManagementStorageObject *)fetchOrCreateStorageObjectWithStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    NSString *accountUniqueId = [self accountUniqueIdForStream:stream];
    OTRStreamManagementStorageObject *storageObject = [OTRStreamManagementStorageObject fetchObjectWithUniqueID:accountUniqueId transaction:transaction];
    
    if (!storageObject) {
        storageObject = [[OTRStreamManagementStorageObject alloc] initWithUniqueId:accountUniqueId];
    } else {
        storageObject = [storageObject copy];
    }
    
    return storageObject;
}

/**
 * Invoked after we receive <enabled/> from the server.
 *
 * @param resumptionId
 *   The ID required to resume the session, given to us by the server.
 *
 * @param timeout
 *   The timeout in seconds.
 *   After a disconnect, the server will maintain our state for this long.
 *   If we attempt to resume the session after this timeout it likely won't work.
 *
 * @param lastDisconnect
 *   Used to reset the lastDisconnect value.
 *   This value is often updated during the session, to ensure it closely resemble the date the server will use.
 *   That is, if the client application is killed (or crashes) we want a relatively accurate lastDisconnect date.
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 *
 * This method should also nil out the following values (if needed) associated with the account:
 * - lastHandledByClient
 * - lastHandledByServer
 * - pendingOutgoingStanzas
 **/
- (void)setResumptionId:(NSString *)resumptionId
                timeout:(uint32_t)timeout
         lastDisconnect:(NSDate *)date
              forStream:(XMPPStream *)stream
{
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRStreamManagementStorageObject *storageObject = [self fetchOrCreateStorageObjectWithStream:stream transaction:transaction];
        storageObject.timeout = timeout;
        storageObject.lastDisconnectDate = date;
        storageObject.resumptionId = resumptionId;
        
        [storageObject saveWithTransaction:transaction];
    }];
    
}

/**
 * This method is invoked ** often ** during stream operation.
 * It is not invoked when the xmppStream is disconnected.
 *
 * Important: See the note below: "Optimizing storage demands during active stream usage"
 *
 * @param date
 *   Updates the previous lastDisconnect value.
 *
 * @param lastHandledByClient
 *   The most recent 'h' value we can safely send to the server.
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 **/
- (void)setLastDisconnect:(NSDate *)date
      lastHandledByClient:(uint32_t)lastHandledByClient
                forStream:(XMPPStream *)stream
{
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRStreamManagementStorageObject *storageObject = [self fetchOrCreateStorageObjectWithStream:stream transaction:transaction];
        storageObject.lastDisconnectDate = date;
        storageObject.lastHandledByClient = lastHandledByClient;
        
        [storageObject saveWithTransaction:transaction];
    }];
}

/**
 * This method is invoked ** often ** during stream operation.
 * It is not invoked when the xmppStream is disconnected.
 *
 * Important: See the note below: "Optimizing storage demands during active stream usage"
 *
 * @param date
 *   Updates the previous lastDisconnect value.
 *
 * @param lastHandledByServer
 *   The most recent 'h' value we've received from the server.
 *
 * @param pendingOutgoingStanzas
 *   An array of XMPPStreamManagementOutgoingStanza objects.
 *   The storage layer is in charge of properly persisting this array, including:
 *   - the array count
 *   - the stanzaId of each element, including those that are nil
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 **/
- (void)setLastDisconnect:(NSDate *)date
      lastHandledByServer:(uint32_t)lastHandledByServer
   pendingOutgoingStanzas:(NSArray *)pendingOutgoingStanzas
                forStream:(XMPPStream *)stream
{
    //TODO: only do saves every so often
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRStreamManagementStorageObject *storageObject = [self fetchOrCreateStorageObjectWithStream:stream transaction:transaction];
        storageObject.lastDisconnectDate = date;
        storageObject.lastHandledByServer = lastHandledByServer;
        storageObject.pendingOutgoingStanzasArray = pendingOutgoingStanzas;
        
        [storageObject saveWithTransaction:transaction];
    }];
}


/// ***** Optimizing storage demands during active stream usage *****
///
/// There are 2 methods that are invoked frequently during stream activity:
///
/// - setLastDisconnect:lastHandledByClient:forStream:
/// - setLastDisconnect:lastHandledByServer:pendingOutgoingStanzas:forStream:
///
/// They are invoked any time the 'h' values change, or whenver the pendingStanzaIds change.
/// In other words, they are invoked continually as stanzas get sent and received.
/// And it is the job of the storage layer to decide how to handle the traffic.
/// There are a few things to consider here:
///
/// - How much chatter does the xmppStream do?
/// - How fast is the storage layer?
/// - How does the overhead on the storage layer affect the rest of the app?
///
/// If your xmppStream isn't very chatty, and you've got a fast concurrent database,
/// then you may be able to simply pipe all these method calls to the database without thinking.
/// However, if your xmppStream is always constantly sending/receiving presence stanzas, and pinging the server,
/// then you might consider a bit of optimzation here. Below is a simple recommendation for how to accomplish this.
///
/// You could choose to queue the changes from these method calls, and dump them to the database after a timeout.
/// Thus you'll be able to consolidate a large traffic surge into a small handful of database operations.
///
/// Also, you could expose a 'flush' operation on the storage layer.
/// And invoke the flush operation when the app is backgrounded, or about to quit.


/**
 * This method is invoked immediately after an accidental disconnect.
 * And may be invoked post-disconnect if the state changes, such as for the following edge cases:
 *
 * - due to continued processing of stanzas received pre-disconnect,
 *   that are just now being marked as handled by the delegate(s)
 * - due to a delayed response from the delegate(s),
 *   such that we didn't receive the stanzaId for an outgoing stanza until after the disconnect occurred.
 *
 * This method is not invoked if stream management is started on a connected xmppStream.
 *
 * @param date
 *   This value will be the actual disconnect date.
 *
 * @param lastHandledByClient
 *   The most recent 'h' value we can safely send to the server.
 *
 * @param lastHandledByServer
 *   The most recent 'h' value we've received from the server.
 *
 * @param pendingOutgoingStanzas
 *   An array of XMPPStreamManagementOutgoingStanza objects.
 *   The storage layer is in charge of properly persisting this array, including:
 *   - the array count
 *   - the stanzaId of each element, including those that are nil
 *
 * @param stream
 *   The associated xmppStream (standard parameter for storage classes)
 **/
- (void)setLastDisconnect:(NSDate *)date
      lastHandledByClient:(uint32_t)lastHandledByClient
      lastHandledByServer:(uint32_t)lastHandledByServer
   pendingOutgoingStanzas:(NSArray *)pendingOutgoingStanzas
                forStream:(XMPPStream *)stream
{
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRStreamManagementStorageObject *storageObject = [self fetchOrCreateStorageObjectWithStream:stream transaction:transaction];
        storageObject.lastDisconnectDate = date;
        storageObject.lastHandledByClient = lastHandledByClient;
        storageObject.lastHandledByServer = lastHandledByServer;
        storageObject.pendingOutgoingStanzasArray = pendingOutgoingStanzas;
        
        [storageObject saveWithTransaction:transaction];
    }];
}

/**
 * Invoked when the extension needs values from a previous session.
 * This method is used to get values needed in order to determine if it can resume a previous stream.
 **/
- (void)getResumptionId:(NSString * __autoreleasing *)resumptionIdPtr
                timeout:(uint32_t *)timeoutPtr
         lastDisconnect:(NSDate * __autoreleasing *)lastDisconnectPtr
              forStream:(XMPPStream *)stream
{
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRStreamManagementStorageObject *storageObject = [OTRStreamManagementStorageObject fetchObjectWithUniqueID:[self accountUniqueIdForStream:stream] transaction:transaction];
        if (storageObject) {
            *resumptionIdPtr = storageObject.resumptionId;
            *timeoutPtr = storageObject.timeout;
            *lastDisconnectPtr = storageObject.lastDisconnectDate;
        }
    }];
}

/**
 * Invoked when the extension needs values from a previous session.
 * This method is used to get values needed in order to resume a previous stream.
 **/
- (void)getLastHandledByClient:(uint32_t * _Nullable)lastHandledByClientPtr
           lastHandledByServer:(uint32_t * _Nullable)lastHandledByServerPtr
        pendingOutgoingStanzas:(NSArray<XMPPStreamManagementOutgoingStanza*> * _Nullable __autoreleasing * _Nullable)pendingOutgoingStanzasPtr
                     forStream:(XMPPStream *)stream;
{
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRStreamManagementStorageObject *storageObject = [OTRStreamManagementStorageObject fetchObjectWithUniqueID:[self accountUniqueIdForStream:stream] transaction:transaction];
        if (storageObject) {
            *lastHandledByClientPtr = storageObject.lastHandledByClient;
            *lastHandledByServerPtr = storageObject.lastHandledByServer;
            *pendingOutgoingStanzasPtr = storageObject.pendingOutgoingStanzasArray;
        }
    }];
}

/**
 * Instructs the storage layer to remove all values stored for the given stream.
 * This occurs after the extension detects a "cleanly closed stream",
 * in which case the stream cannot be resumed next time.
 **/
- (void)removeAllForStream:(XMPPStream *)stream
{
    [self.databaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction removeObjectForKey:[self accountUniqueIdForStream:stream]
                           inCollection:[OTRStreamManagementStorageObject collection]];
    }];
}

@end
