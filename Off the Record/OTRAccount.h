//
//  OTRAccount.h
//  Off the Record
//
//  Created by Chris Ballinger on 6/26/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kOTRAccountUsernameKey @"kOTRAccountUsernameKey"
#define kOTRAccountProtocolKey @"kOTRAccountProtocolKey"
#define kOTRAccountRememberPasswordKey @"kOTRAccountRememberPasswordKey"

#define kAIMImageName @"aim.png"
#define kGTalkImageName @"gtalk.png"
#define kFacebookImageName @"facebook.png"
#define kXMPPImageName @"xmpp.png"

@interface OTRAccount : NSObject

@property (nonatomic, retain) NSString *username; // 
@property (nonatomic, retain) NSString *protocol; // kOTRProtocolType, defined in OTRProtocolManager.h
@property (nonatomic, retain) NSString *password; // nil if rememberPassword = NO, not stored in memory
@property (nonatomic, readonly) NSString *uniqueIdentifier;
@property (nonatomic) BOOL rememberPassword;
@property (nonatomic) BOOL isConnected;

- (id) initWithProtocol:(NSString*)newProtocol;
- (id) initWithSettingsDictionary:(NSDictionary*)dictionary uniqueIdentifier:(NSString*)uniqueID;
- (void) save;
- (Class)protocolClass;
- (NSString *) providerName;
- (NSString *) imageName;
- (NSMutableDictionary*) accountDictionary;

@end
