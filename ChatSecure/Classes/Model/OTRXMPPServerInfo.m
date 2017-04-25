//
//  OTRXMPPServerInfo.m
//  ChatSecure
//
//  Created by David Chiles on 6/4/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPServerInfo.h"
@import OTRAssets;

/*
 {
 "name": "Calyx Institute",
 "description": "Non-profit education and research organization focused on privacy technology.",
 "website": "https://www.calyxinstitute.org",
 "twitter": "https://twitter.com/calyxinstitute",
 "privacy_policy": "https://www.calyxinstitute.org/legal/privacy-policy",
 "logo": "images/calyx.jpg",
 "country_code": "US",
 "domain": "calyxinstitute.org",
 "server": "conference.calyxinstitute.org",
 "onion": "ijeeynrc6x2uy5ob.onion",
 "port": 5222,
 "certificate": "..."
 }
 */

@interface OTRXMPPServerInfo ()
@property (nonatomic, readonly) NSArray<NSString*> *extensions;
@end

static NSArray<OTRXMPPServerInfo*> *_defaultServerList = nil;

@implementation OTRXMPPServerInfo
@synthesize portNumber = _portNumber;
@synthesize websiteURL = _websiteURL;
@synthesize twitterURL = _twitterURL;
@synthesize privacyPolicyURL = _privacyPolicyURL;

- (instancetype) initWithDomain:(NSString*)domain {
    if (self = [super init]) {
        _domain = [domain copy];
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"name": @"name",
             @"serverDescription": @"description",
             @"websiteURL": @"website",
             @"twitterURL": @"twitter",
             @"privacyPolicyURL": @"privacy_policy",
             @"logo": @"logo",
             @"countryCode": @"country_code",
             @"domain": @"domain",
             @"server": @"server",
             @"onion": @"onion",
             @"portNumber": @"port",
             @"certificate": @"certificate",
             @"requiresCaptcha": @"captcha",
             @"extensions": @"extensions"
             };
}

+ (NSValueTransformer *)websiteURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)twitterURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)privacyPolicyURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

- (UIImage*) logoImage {
    UIImage *defaultImage = [UIImage imageNamed:@"xmpp" inBundle:[OTRAssets resourcesBundle] compatibleWithTraitCollection:nil]; // load default image
    NSParameterAssert(defaultImage);
    NSBundle *bundle = [[self class] serverBundle];
    NSArray *pathComponents = [self.logo pathComponents];
    if (pathComponents.count < 2) {
        return defaultImage;
    }
    NSString *folder = pathComponents[0];
    NSString *fileName = pathComponents[1];
    NSString *extension = [fileName pathExtension];
    NSString *resource = [fileName stringByDeletingPathExtension];
    NSString *path = [bundle pathForResource:resource ofType:extension inDirectory:folder];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if (!image) {
        image = defaultImage;
    }
    NSParameterAssert(image);
    return image;
}

- (in_port_t) portNumber {
    if (_portNumber > 0) {
        return _portNumber;
    }
    return 5222;
}

- (NSURL*) websiteURL {
    if (_websiteURL.absoluteString.length == 0) {
        return nil;
    }
    return _websiteURL;
}

- (NSURL*) twitterURL {
    if (_twitterURL.absoluteString.length == 0) {
        return nil;
    }
    return _twitterURL;
}

- (NSURL*) privacyPolicyURL {
    if (_privacyPolicyURL.absoluteString.length == 0) {
        return nil;
    }
    return _privacyPolicyURL;
}

- (NSSet<NSString*>*) supportedXEPs {
    if (!self.extensions) {
        return [NSSet set];
    }
    return [NSSet setWithArray:self.extensions];
}

+ (NSBundle*)serverBundle {
    NSString *folderName = @"xmpp-server-list";
    NSString *bundlePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:folderName];
    NSBundle *dataBundle = [NSBundle bundleWithPath:bundlePath];
    NSParameterAssert(dataBundle);
    return dataBundle;
}

+ (NSArray *)defaultServerList
{
    if (_defaultServerList) {
        return _defaultServerList;
    }
    NSBundle *dataBundle = [self serverBundle];
    NSURL *url = [dataBundle URLForResource:@"servers" withExtension:@"json"];
    NSParameterAssert(url != nil);
    
    NSData *jsonData = [[NSData alloc] initWithContentsOfURL:url];
    _defaultServerList = [self serverListFromJSONData:jsonData];
    return _defaultServerList;
}

+ (nullable NSArray<OTRXMPPServerInfo*> *)serverListFromJSONData:(NSData*)jsonData {
    NSSet *desiredXEPs = [[self class] desiredXEPs];
    return [self serverListFromJSONData:jsonData filterBlock:^BOOL(OTRXMPPServerInfo * _Nonnull server) {
        BOOL result = server.requiresCaptcha == NO;
        if (!result) {
            return NO;
        }
        NSSet *supportedXEPs = server.supportedXEPs;
        result = result && [desiredXEPs isSubsetOfSet:supportedXEPs];
        return result;
    }];
}

+ (nullable NSArray<OTRXMPPServerInfo*> *)serverListFromJSONData:(NSData*)jsonData filterBlock:(nonnull BOOL (^)(OTRXMPPServerInfo * _Nonnull))filterBlock {
    NSParameterAssert(jsonData != nil);
    NSParameterAssert(filterBlock != nil);
    NSError *error = nil;
    NSDictionary *root = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    NSParameterAssert(root != nil);
    if (error) {
        NSLog(@"Error parsing server list JSON: %@", error);
        return nil;
    }
    NSArray *serverDictionaries = root[@"servers"];
    NSParameterAssert(serverDictionaries);
    NSArray *servers = [MTLJSONAdapter modelsOfClass:[self class] fromJSONArray:serverDictionaries error:&error];
    if (error) {
        NSLog(@"Error parsing server list JSON: %@", error);
        return nil;
    }
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(OTRXMPPServerInfo *evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return filterBlock(evaluatedObject);
    }];
    servers = [servers filteredArrayUsingPredicate:predicate];
    return servers;
}

+ (NSString*) XEP_0357 {
    return @"XEP-0357";
}

+ (NSString*) XEP_0363 {
    return @"XEP-0363";
}

+ (NSSet<NSString*>*) desiredXEPs {
    return [NSSet setWithObjects:self.XEP_0357, self.XEP_0363, nil];
}

@end
