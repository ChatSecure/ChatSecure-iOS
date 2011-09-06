//
//  OTRProtocolManager.h
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTROscarManager.h"
#import "OTREncryptionManager.h"

@interface OTRProtocolManager : NSObject
{
    
}

@property (nonatomic, retain) OTROscarManager *oscarManager;
@property (nonatomic, retain) OTREncryptionManager *encryptionManager;

+ (OTRProtocolManager*)sharedInstance; // Singleton method


@end
