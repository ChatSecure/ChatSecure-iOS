//
//  OTREncryptionManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 9/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OTREncryptionManager.h"

#import "message.h"
#import "privkey.h"

#define PRIVKEYFNAME @"otr.private_key"
#define STOREFNAME @"otr.fingerprints"

@implementation OTREncryptionManager

-(id)init
{
    self = [super init];
    
    if(self)
    {
        // initialize OTR
        OTRL_INIT;
        s_OTR_userState = otrl_userstate_create();
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        //otrl_privkey_read(OTR_userState,"privkeyfilename");
        FILE *privf;
        NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",PRIVKEYFNAME]];
        privf = fopen([path UTF8String], "rb");
        
        if(privf)
            otrl_privkey_read_FILEp(s_OTR_userState, privf);
        fclose(privf);
        
        //otrl_privkey_read_fingerprints(OTR_userState, "fingerprintfilename", NULL, NULL);
        FILE *storef;
        path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",STOREFNAME]];
        storef = fopen([path UTF8String], "rb");
        
        if (storef)
            otrl_privkey_read_fingerprints_FILEp(s_OTR_userState, storef, NULL, NULL);
        fclose(storef);
    }
    
    return self;
}

+(OtrlUserState) OTR_userState
{
    return s_OTR_userState;
}

@end
