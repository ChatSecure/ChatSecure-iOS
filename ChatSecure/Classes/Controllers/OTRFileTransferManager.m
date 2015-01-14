//
//  OTRFileTransferManager.m
//  ChatSecure
//
//  Created by Christopher Ballinger on 1/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRFileTransferManager.h"
#import "OTRLog.h"

@implementation OTRFileTransferManager

- (void)dataHandler:(OTRDataHandler*)dataHandler
           transfer:(OTRDataTransfer*)transfer
              error:(NSError*)error {
    DDLogError(@"error with file transfer: %@ %@", transfer, error);
}

- (void)dataHandler:(OTRDataHandler*)dataHandler
    offeredTransfer:(OTRDataIncomingTransfer*)transfer {
    DDLogInfo(@"offered file transfer: %@", transfer);

    // for now, just accept all incoming files
#warning auto-accept of all incoming files
    [dataHandler startIncomingTransfer:transfer];
}

- (void)dataHandler:(OTRDataHandler*)dataHandler
           transfer:(OTRDataTransfer*)transfer
           progress:(float)progress {
    DDLogInfo(@"file transfer progress: %@ %f", transfer, progress);

}

- (void)dataHandler:(OTRDataHandler*)dataHandler
   transferComplete:(OTRDataTransfer*)transfer {
    DDLogInfo(@"transfer complete: %@", transfer);
}


@end
