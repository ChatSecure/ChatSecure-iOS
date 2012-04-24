//
//  OTRSettingsManager.m
//  Off the Record
//
//  Created by Chris Ballinger on 4/10/12.
//  Copyright (c) 2012 Chris Ballinger. All rights reserved.
//

#import "OTRSettingsManager.h"
#import "OTRViewSetting.h"
#import "Strings.h"
#import "OTRAccountsViewController.h"
#import "OTRSettingsGroup.h"
#import "OTRSetting.h"
#import "OTRBoolSetting.h"
#import "OTRViewSetting.h"

@interface OTRSettingsManager(Private)
- (void) populateSettings;
@end

@implementation OTRSettingsManager
@synthesize settingsGroups;

- (void) dealloc
{
    settingsGroups = nil;
}

- (id) init
{
    if (self = [super init])
    {
        settingsGroups = [NSMutableArray array];
        [self populateSettings];
    }
    return self;
}

- (void) populateSettings
{
    OTRViewSetting *accountsViewSetting = [[OTRViewSetting alloc] initWithTitle:ACCOUNTS_STRING description:nil viewControllerClass:[OTRAccountsViewController class]];
    OTRSettingsGroup *accountsGroup = [[OTRSettingsGroup alloc] initWithTitle:ACCOUNTS_STRING settings:[NSArray arrayWithObject:accountsViewSetting]];
    [settingsGroups addObject:accountsGroup];
    
    OTRBoolSetting *allowSelfSignedCertificates = [[OTRBoolSetting alloc] initWithTitle:ALLOW_SELF_SIGNED_CERTIFICATES_STRING description:SECURITY_WARNING_STRING settingsKey:kOTRSettingKeyAllowSelfSignedSSL];
    OTRBoolSetting *allowSSLHostnameMismatch = [[OTRBoolSetting alloc] initWithTitle:ALLOW_SSL_HOSTNAME_MISMATCH_STRING description:SECURITY_WARNING_STRING settingsKey:kOTRSettingKeyAllowSSLHostNameMismatch];
    OTRSettingsGroup *xmppGroup = [[OTRSettingsGroup alloc] initWithTitle:@"XMPP" settings:[NSArray arrayWithObjects:allowSelfSignedCertificates, allowSSLHostnameMismatch, nil]];
    [settingsGroups addObject:xmppGroup];
    
    
#ifdef CRITTERCISM_ENABLED
    OTRBoolSetting *crittercismSetting = [[OTRBoolSetting alloc] initWithTitle:CRITTERCISM_TITLE_STRING description:CRITTERCISM_DESCRIPTION_STRING settingsKey:kOTRSettingKeyCrittercismOptIn];
    OTRSettingsGroup *otherGroup = [[OTRSettingsGroup alloc] initWithTitle:OTHER_STRING settings:[NSArray arrayWithObject:crittercismSetting]];
    [settingsGroups addObject:otherGroup];
#endif
}

- (OTRSetting*) settingAtIndexPath:(NSIndexPath*)indexPath
{
    OTRSettingsGroup *settingsGroup = [settingsGroups objectAtIndex:indexPath.section];
    return [settingsGroup.settings objectAtIndex:indexPath.row];
}

- (NSString*) stringForGroupInSection:(NSUInteger)section
{
    OTRSettingsGroup *settingsGroup = [settingsGroups objectAtIndex:section];
    return settingsGroup.title;
}

- (NSUInteger) numberOfSettingsInSection:(NSUInteger)section
{
    OTRSettingsGroup *settingsGroup = [settingsGroups objectAtIndex:section];
    return [settingsGroup.settings count];
}

+ (BOOL) boolForOTRSettingKey:(NSString*)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}

+ (double) doubleForOTRSettingKey:(NSString*)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults doubleForKey:key];
}

@end
